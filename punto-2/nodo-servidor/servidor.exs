# Punto 2: Nodo Servidor de Consultas Sísmicas
# Observatorio Sismológico de la Universidad del Quindío

unless Node.alive?() do
  IO.puts(:stderr, """
  ================================================================================
  [ERROR] El nodo no está iniciado en modo distribuido.
  Debe ejecutar este script especificando un nombre corto (--sname) y una cookie (--cookie).
  Ejemplo:
    elixir --sname servidor --cookie sismos_secret servidor.exs
  ================================================================================
  """)
  System.halt(1)
end

dir_base = __DIR__

# Reutilización de módulos, structs, validaciones y cálculos del Punto 1
Code.require_file("modelos.exs", dir_base)
Code.require_file("validador.exs", dir_base)
Code.require_file("lector.exs", dir_base)
Code.require_file("calculador.exs", dir_base)
Code.require_file("reporte.exs", dir_base)

defmodule ServidorSismos do
  @moduledoc """
  Proceso servidor que atiende consultas de sismos distribuidas entre nodos.
  Registrado globalmente en el nodo como :servicio_sismos.
  """

  @doc """
  Inicia el bucle recursivo del servidor.
  """
  def iniciar(ruta_ciudades, ruta_movimientos) do
    Process.register(self(), :servicio_sismos)

    IO.puts("================================================================================")
    IO.puts("             OBSERVATORIO SISMOLÓGICO - NODO SERVIDOR ACTIVO")
    IO.puts("================================================================================")
    IO.puts("Nodo Servidor:  #{Node.self()}")
    IO.puts("Cookie activa:  #{Node.get_cookie()}")
    IO.puts("Proceso:        :servicio_sismos")
    IO.puts("Ruta Ciudades:  #{ruta_ciudades}")
    IO.puts("Ruta Movs:      #{ruta_movimientos}")
    IO.puts("Estado:         Esperando solicitudes de clientes...\n")

    bucle_servicio(ruta_ciudades, ruta_movimientos)
  end

  defp bucle_servicio(ruta_ciudades, ruta_movimientos) do
    receive do
      {destino_respuesta, {:reporte_ciudad, id_ciudad}} ->
        IO.puts("[SERVIDOR] <-- Recibida solicitud {:reporte_ciudad, #{inspect(id_ciudad)}} desde #{inspect(destino_respuesta)}")
        respuesta = responder_reporte_ciudad(id_ciudad, ruta_ciudades, ruta_movimientos)
        send(destino_respuesta, respuesta)
        IO.puts("[SERVIDOR] --> Enviada respuesta de ciudad '#{id_ciudad}' a #{inspect(destino_respuesta)}\n")
        bucle_servicio(ruta_ciudades, ruta_movimientos)

      {destino_respuesta, :reporte_general} ->
        IO.puts("[SERVIDOR] <-- Recibida solicitud :reporte_general desde #{inspect(destino_respuesta)}")
        respuesta = responder_reporte_general(ruta_ciudades, ruta_movimientos)
        send(destino_respuesta, respuesta)
        IO.puts("[SERVIDOR] --> Enviada respuesta de reporte general a #{inspect(destino_respuesta)}\n")
        bucle_servicio(ruta_ciudades, ruta_movimientos)

      {destino_respuesta, :fin} ->
        IO.puts("[SERVIDOR] <-- Recibida señal :fin desde #{inspect(destino_respuesta)}")
        send(destino_respuesta, :fin)
        IO.puts("[SERVIDOR] --> Confirmación :fin enviada al cliente. Servidor permanece a la espera.\n")
        bucle_servicio(ruta_ciudades, ruta_movimientos)

      mensaje_desconocido ->
        IO.puts(:stderr, "[SERVIDOR WARN] Mensaje no reconocido: #{inspect(mensaje_desconocido)}")
        bucle_servicio(ruta_ciudades, ruta_movimientos)
    end
  end

  # Lectura concurrente de las versiones actuales de ambos archivos
  defp leer_archivos_concurrentemente(ruta_ciudades, ruta_movimientos) do
    coordinador = self()

    _pid_c =
      spawn(fn ->
        resultado = Lector.leer_archivo_ciudades(ruta_ciudades)
        send(coordinador, {:archivo_ciudades, resultado})
      end)

    _pid_m =
      spawn(fn ->
        resultado = Lector.leer_archivo_movimientos(ruta_movimientos)
        send(coordinador, {:archivo_movimientos, resultado})
      end)

    esperar_trabajadores(nil, nil)
  end

  defp esperar_trabajadores(res_ciudades, res_movimientos) do
    case {res_ciudades, res_movimientos} do
      {nil, _} ->
        receive do
          {:archivo_ciudades, res} -> esperar_trabajadores(res, res_movimientos)
          {:archivo_movimientos, res} -> esperar_trabajadores(res_ciudades, res)
        end

      {_, nil} ->
        receive do
          {:archivo_ciudades, res} -> esperar_trabajadores(res, res_movimientos)
          {:archivo_movimientos, res} -> esperar_trabajadores(res_ciudades, res)
        end

      {res_c, res_m} ->
        {res_c, res_m}
    end
  end

  # Procesa la solicitud {:reporte_ciudad, idCiudad}
  defp responder_reporte_ciudad(id_ciudad, ruta_ciudades, ruta_movimientos) do
    case leer_archivos_concurrentemente(ruta_ciudades, ruta_movimientos) do
      {{:error, {ruta_c, _}}, {:error, {ruta_m, _}}} ->
        "Error: No se pudieron leer los archivos de entrada (#{ruta_c} y #{ruta_m})."

      {{:error, {ruta_c, _}}, _} ->
        "Error: No se pudo leer el archivo de ciudades (#{ruta_c})."

      {_, {:error, {ruta_m, _}}} ->
        "Error: No se pudo leer el archivo de movimientos (#{ruta_m})."

      {{:ok, {ciudades, _rech_c}}, {:ok, {movs_brutos, rech_m_sintaxis}}} ->
        {movs_validos, _rech_m_total} =
          Calculador.filtrar_movimientos_por_ciudades(movs_brutos, ciudades, rech_m_sintaxis)

        case Enum.find(ciudades, fn c -> c.id_ciudad == id_ciudad end) do
          nil ->
            # "Si el identificador no corresponde a una ciudad válida, el servidor deberá responder «La ciudad no está registrada»."
            "La ciudad no está registrada"

          ciudad ->
            movs_ciudad = Enum.filter(movs_validos, fn m -> m.id_ciudad == id_ciudad end)
            stats = Calculador.calcular_estadisticas_movimientos(movs_ciudad)

            FormateadorReporte.formatear_reporte_ciudad(%{
              ciudad: ciudad,
              movimientos: movs_ciudad,
              stats: stats
            })
        end
    end
  end

  # Procesa la solicitud :reporte_general
  defp responder_reporte_general(ruta_ciudades, ruta_movimientos) do
    case leer_archivos_concurrentemente(ruta_ciudades, ruta_movimientos) do
      {{:error, {ruta_c, _}}, {:error, {ruta_m, _}}} ->
        "Error: No se pudieron leer los archivos de entrada (#{ruta_c} y #{ruta_m})."

      {{:error, {ruta_c, _}}, _} ->
        "Error: No se pudo leer el archivo de ciudades (#{ruta_c})."

      {_, {:error, {ruta_m, _}}} ->
        "Error: No se pudo leer el archivo de movimientos (#{ruta_m})."

      {{:ok, {ciudades, rech_c}}, {:ok, {movs_brutos, rech_m_sintaxis}}} ->
        {movs_validos, rech_m_total} =
          Calculador.filtrar_movimientos_por_ciudades(movs_brutos, ciudades, rech_m_sintaxis)

        datos_ciudades = Calculador.procesar_datos_ciudades(ciudades, movs_validos)
        FormateadorReporte.formatear_reporte_general(datos_ciudades, rech_c, rech_m_total)
    end
  end
end

ruta_ciudades = Path.join(dir_base, "resources/ciudades.txt")
ruta_movimientos = Path.join(dir_base, "resources/movimientos.txt")

ServidorSismos.iniciar(ruta_ciudades, ruta_movimientos)
