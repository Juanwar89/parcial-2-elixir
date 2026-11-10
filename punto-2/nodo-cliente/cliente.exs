# Punto 2: Nodo Cliente de Consultas Sísmicas
# Observatorio Sismológico de la Universidad del Quindío

unless Node.alive?() do
  IO.puts(:stderr, """
  ================================================================================
  [ERROR] El nodo cliente no está iniciado en modo distribuido.
  Debe ejecutar este script especificando un nombre corto (--sname) y una cookie (--cookie).
  Ejemplo:
    elixir --sname cliente --cookie sismos_secret cliente.exs
  ================================================================================
  """)
  System.halt(1)
end

defmodule ClienteSismos do
  @moduledoc """
  Nodo cliente que se conecta al nodo servidor, envía consultas y
  recibe recursivamente las respuestas hasta recibir :fin.
  """

  @doc """
  Ejecuta el flujo completo del cliente:
  1. Registra el proceso :servicio_respuesta.
  2. Conecta con el nodo servidor mediante Node.connect/1.
  3. Envía las 5 solicitudes en el orden exacto especificado.
  4. Recibe recursivamente las respuestas hasta :fin.
  """
  def ejecutar(servidor_nodo, id_con_mov, id_sin_mov, id_inexistente) do
    # 1. Registrar proceso localmente con el nombre :servicio_respuesta
    Process.register(self(), :servicio_respuesta)

    IO.puts("================================================================================")
    IO.puts("             OBSERVATORIO SISMOLÓGICO - NODO CLIENTE ACTIVO")
    IO.puts("================================================================================")
    IO.puts("Nodo Cliente:     #{Node.self()}")
    IO.puts("Cookie activa:    #{Node.get_cookie()}")
    IO.puts("Proceso:          :servicio_respuesta")
    IO.puts("Conectando con:   #{servidor_nodo} ...")

    # 2. Conectar al nodo servidor
    case Node.connect(servidor_nodo) do
      true ->
        IO.puts("[CONEXIÓN EXITOSA] Conectado al nodo servidor #{servidor_nodo}.\n")
        enviar_y_recibir(servidor_nodo, id_con_mov, id_sin_mov, id_inexistente)

      false ->
        IO.puts(:stderr, """
        ================================================================================
        [ERROR DE CONEXIÓN]
        No fue posible conectar con el nodo servidor: #{inspect(servidor_nodo)}
        Verifique que:
        1. El servidor esté iniciado en otra terminal:
           elixir --sname servidor --cookie #{Node.get_cookie()} servidor.exs
        2. Ambos nodos compartan exactamente la misma cookie.
        3. Si el servidor está en otra máquina o nombre, páselo como argumento:
           elixir --sname cliente --cookie #{Node.get_cookie()} cliente.exs servidor@nombre_host
        ================================================================================
        """)
        System.halt(1)

      :ignored ->
        IO.puts(:stderr, "[ERROR] El nodo local no está activo en modo distribuido.")
        System.halt(1)
    end
  end

  defp enviar_y_recibir(servidor_nodo, id_con_mov, id_sin_mov, id_inexistente) do
    destino_respuesta = {:servicio_respuesta, Node.self()}
    proceso_servidor = {:servicio_sismos, servidor_nodo}

    IO.puts("--------------------------------------------------------------------------------")
    IO.puts("ENVIANDO SOLICITUDES EN EL ORDEN ESPECIFICADO:")
    IO.puts("--------------------------------------------------------------------------------")

    # 1. El reporte de una ciudad con movimientos registrados
    IO.puts("1. Enviando: {:reporte_ciudad, \"#{id_con_mov}\"} (ciudad con movimientos)")
    send(proceso_servidor, {destino_respuesta, {:reporte_ciudad, id_con_mov}})

    # 2. El reporte de una ciudad sin movimientos registrados
    IO.puts("2. Enviando: {:reporte_ciudad, \"#{id_sin_mov}\"} (ciudad sin movimientos)")
    send(proceso_servidor, {destino_respuesta, {:reporte_ciudad, id_sin_mov}})

    # 3. El reporte de una ciudad con identificador inexistente
    IO.puts("3. Enviando: {:reporte_ciudad, \"#{id_inexistente}\"} (ciudad inexistente)")
    send(proceso_servidor, {destino_respuesta, {:reporte_ciudad, id_inexistente}})

    # 4. El reporte general
    IO.puts("4. Enviando: :reporte_general (todas las ciudades)")
    send(proceso_servidor, {destino_respuesta, :reporte_general})

    # 5. El mensaje :fin
    IO.puts("5. Enviando: :fin (finalización de solicitudes)")
    send(proceso_servidor, {destino_respuesta, :fin})

    IO.puts("--------------------------------------------------------------------------------")
    IO.puts("RECEPCIÓN RECURSIVA DE RESPUESTAS:")
    IO.puts("--------------------------------------------------------------------------------")

    # Recepción recursiva hasta recibir :fin
    recibir_respuestas_rec(1)

    IO.puts("\n[FINALIZADO] Ejecución del cliente finalizada con éxito.")
  end

  # Función con recursividad explícita para recibir las respuestas hasta recibir :fin
  defp recibir_respuestas_rec(contador) do
    receive do
      :fin ->
        IO.puts("\n================================================================================")
        IO.puts("RESPUESTA ##{contador} (FINAL): :fin")
        IO.puts("Confirmación recibida: el servidor ha finalizado el envío de respuestas.")
        IO.puts("================================================================================")
        :ok

      respuesta ->
        IO.puts("\n================================================================================")
        IO.puts("RESPUESTA RECIBIDA ##{contador}:")
        IO.puts("--------------------------------------------------------------------------------")
        IO.puts(respuesta)
        IO.puts("================================================================================")
        recibir_respuestas_rec(contador + 1)
    after
      10_000 ->
        IO.puts(:stderr, "\n[ERROR] Tiempo de espera agotado (timeout) esperando respuesta del servidor.")
    end
  end
end

# Determinación automática o por argumento del nodo servidor
servidor_nodo =
  case System.argv() do
    [nombre | _] ->
      String.to_atom(nombre)

    [] ->
      case String.split(to_string(Node.self()), "@") do
        [_user, host] -> :"servidor@#{host}"
        _ -> :"servidor@localhost"
      end
  end

# Identificadores de prueba:
# 1. Ciudad con movimientos: "C01" (Armenia)
# 2. Ciudad sin movimientos: "C03" (Circasia)
# 3. Ciudad inexistente: "C99"
ClienteSismos.ejecutar(servidor_nodo, "C01", "C03", "C99")
