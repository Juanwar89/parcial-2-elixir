defmodule Coordinador do
  @moduledoc """
  Módulo coordinador de la generación del reporte local (Punto 1).
  Gestiona la concurrencia utilizando spawn, send y receive.
  Inicia los trabajadores de lectura concurrentemente antes de esperar sus respuestas,
  acepta los mensajes en cualquier orden y maneja los errores de lectura y escritura.
  """

  @doc """
  Inicia el proceso de generación del reporte:
  1. Lanza los dos procesos trabajadores con `spawn`.
  2. Recibe las respuestas en cualquier orden con `receive`.
  3. Si hay errores de lectura, indica cuál archivo falló y conserva el reporte anterior.
  4. Si ambos fueron exitosos, filtra datos, calcula estadísticas, imprime en consola
     y guarda en `ruta_salida`.
  """
  def generar_reporte(ruta_ciudades, ruta_movimientos, ruta_salida) do
    coordinador = self()

    # 1. Iniciar ambos trabajadores ANTES de esperar sus respuestas
    _pid_ciudades =
      spawn(fn ->
        resultado = Lector.leer_archivo_ciudades(ruta_ciudades)
        send(coordinador, {:archivo_ciudades, resultado})
      end)

    _pid_movimientos =
      spawn(fn ->
        resultado = Lector.leer_archivo_movimientos(ruta_movimientos)
        send(coordinador, {:archivo_movimientos, resultado})
      end)

    # 2. Esperar respuestas concurrentes en cualquier orden
    {res_ciudades, res_movimientos} = esperar_trabajadores(nil, nil)

    # 3. Manejar errores de lectura
    case {res_ciudades, res_movimientos} do
      {{:error, {ruta_c, motivo_c}}, {:error, {ruta_m, motivo_m}}} ->
        IO.puts(:stderr, "\n[ERROR] No fue posible leer ninguno de los dos archivos de entrada:")
        IO.puts(:stderr, " - Archivo de ciudades: '#{ruta_c}' (#{inspect(motivo_c)})")
        IO.puts(:stderr, " - Archivo de movimientos: '#{ruta_m}' (#{inspect(motivo_m)})")
        IO.puts(:stderr, "[INFO] Se conserva el reporte anterior intacto.")
        {:error, :fallo_lectura_ambos}

      {{:error, {ruta_c, motivo_c}}, {:ok, _}} ->
        IO.puts(:stderr, "\n[ERROR] Falló la lectura del archivo de ciudades: '#{ruta_c}' (#{inspect(motivo_c)})")
        IO.puts(:stderr, "[INFO] Se conserva el reporte anterior intacto.")
        {:error, :fallo_lectura_ciudades}

      {{:ok, _}, {:error, {ruta_m, motivo_m}}} ->
        IO.puts(:stderr, "\n[ERROR] Falló la lectura del archivo de movimientos: '#{ruta_m}' (#{inspect(motivo_m)})")
        IO.puts(:stderr, "[INFO] Se conserva el reporte anterior intacto.")
        {:error, :fallo_lectura_movimientos}

      {{:ok, {ciudades, rech_ciudades}}, {:ok, {movs_brutos, rech_movs_sintaxis}}} ->
        # 4. Ambos archivos leídos exitosamente. Proceder con el procesamiento
        {movs_validos, rech_movs_total} =
          Calculador.filtrar_movimientos_por_ciudades(movs_brutos, ciudades, rech_movs_sintaxis)

        datos_ciudades = Calculador.procesar_datos_ciudades(ciudades, movs_validos)
        reporte_texto = FormateadorReporte.formatear_reporte_general(datos_ciudades, rech_ciudades, rech_movs_total)

        # Mostrar en consola
        IO.puts(reporte_texto)

        # Guardar en archivo (reemplazando contenido previo)
        guardar_reporte(ruta_salida, reporte_texto)
        {:ok, reporte_texto}
    end
  end

  # Función recursiva para recibir los resultados de ambos trabajadores en cualquier orden
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

  # Guarda el reporte en el archivo indicado, reportando error si falla
  defp guardar_reporte(ruta_salida, contenido) do
    directorio = Path.dirname(ruta_salida)
    if directorio != "." and not File.dir?(directorio) do
      File.mkdir_p!(directorio)
    end

    case File.write(ruta_salida, contenido) do
      :ok ->
        IO.puts("\n[ÉXITO] Reporte guardado satisfactoriamente en: #{ruta_salida}")
        :ok

      {:error, motivo} ->
        # Intento de fallback en sistemas donde File.write sea restringido (por ejemplo en carpetas de OneDrive)
        case intentar_escritura_sistema(ruta_salida, contenido) do
          :ok ->
            IO.puts("\n[ÉXITO] Reporte guardado satisfactoriamente en: #{ruta_salida}")
            :ok

          {:error, _} ->
            IO.puts(:stderr, "\n[ERROR] Falló la escritura del reporte en '#{ruta_salida}': #{inspect(motivo)}")
            {:error, motivo}
        end
    end
  end

  defp intentar_escritura_sistema(ruta_salida, contenido) do
    case :os.type() do
      {:win32, _} ->
        ruta_abs = Path.expand(ruta_salida)
        b64 = Base.encode64(contenido)
        cmd = "[System.IO.File]::WriteAllBytes('#{ruta_abs}', [System.Convert]::FromBase64String('#{b64}'))"
        case System.cmd("powershell", ["-NoProfile", "-Command", cmd]) do
          {_, 0} -> :ok
          _ -> {:error, :fallo_sistema}
        end

      _ ->
        {:error, :no_soportado}
    end
  rescue
    _ -> {:error, :excepcion_escritura}
  end
end
