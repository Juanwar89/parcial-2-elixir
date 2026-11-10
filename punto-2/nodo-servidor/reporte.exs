defmodule FormateadorReporte do
  @moduledoc """
  Módulo para formatear los reportes de sismos en texto claro y estructurado,
  cumpliendo con todos los requerimientos de presentación del parcial.
  """

  @doc """
  Genera el reporte individual de una ciudad.
  Incluye nombre, habitantes, listado de movimientos, total, mayor magnitud y promedio de profundidad.
  """
  def formatear_reporte_ciudad(%{ciudad: ciudad, movimientos: movimientos, stats: stats}) do
    lineas = [
      "================================================================================",
      "REPORTE DE CIUDAD: #{ciudad.nombre} (ID: #{ciudad.id_ciudad})",
      "Número de habitantes: #{ciudad.numero_habitantes}",
      "--------------------------------------------------------------------------------",
      "Movimientos registrados:",
      formatear_movimientos(movimientos),
      "Cantidad total de movimientos: #{stats.cantidad}",
      "Movimiento de mayor magnitud: #{stats.mayor_texto}",
      "Profundidad promedio: #{stats.profundidad_promedio_texto}",
      "================================================================================"
    ]

    Enum.join(lineas, "\n")
  end

  @doc """
  Genera el reporte general completo.
  Incluye el detalle por cada ciudad, tabla resumen y conteo de registros rechazados por archivo.
  """
  def formatear_reporte_general(datos_ciudades, rechazados_ciudades, rechazados_movimientos) do
    bloque_ciudades =
      datos_ciudades
      |> Enum.map(&formatear_detalle_ciudad/1)
      |> Enum.join("\n\n")

    tabla_resumen = formatear_tabla_resumen(datos_ciudades)

    bloque_rechazados = [
      "REGISTROS RECHAZADOS:",
      "- Archivo de ciudades (ciudades.txt): #{rechazados_ciudades} registro(s) rechazado(s)",
      "- Archivo de movimientos (movimientos.txt): #{rechazados_movimientos} registro(s) rechazado(s)"
    ] |> Enum.join("\n")

    [
      "================================================================================",
      "           OBSERVATORIO SISMOLÓGICO DE LA UNIVERSIDAD DEL QUINDÍO",
      "                        REPORTE GENERAL DE SISMOS",
      "================================================================================",
      "",
      "DETALLE POR CIUDAD:",
      "--------------------------------------------------------------------------------",
      bloque_ciudades,
      "",
      "--------------------------------------------------------------------------------",
      "RESUMEN GENERAL:",
      "--------------------------------------------------------------------------------",
      tabla_resumen,
      "",
      "--------------------------------------------------------------------------------",
      bloque_rechazados,
      "================================================================================"
    ]
    |> Enum.join("\n")
  end

  defp formatear_detalle_ciudad(%{ciudad: ciudad, movimientos: movimientos, stats: stats}) do
    [
      "Ciudad: #{ciudad.nombre} (ID: #{ciudad.id_ciudad})",
      "Número de habitantes: #{ciudad.numero_habitantes}",
      "Movimientos registrados:",
      formatear_movimientos(movimientos),
      "Cantidad total de movimientos: #{stats.cantidad}",
      "Movimiento de mayor magnitud: #{stats.mayor_texto}",
      "Profundidad promedio: #{stats.profundidad_promedio_texto}"
    ]
    |> Enum.join("\n")
  end

  defp formatear_movimientos([]) do
    "  Sin movimientos registrados"
  end

  defp formatear_movimientos(movimientos) do
    movimientos
    |> Enum.map(fn m ->
      "  * Código: #{m.codigo} | Inicio: #{m.hora_inicio} | Fin: #{m.hora_final} | Magnitud: #{Calculador.formatear_decimal(m.magnitud)} | Profundidad: #{Calculador.formatear_decimal(m.profundidad)} km"
    end)
    |> Enum.join("\n")
  end

  defp formatear_tabla_resumen(datos_ciudades) do
    encabezado = String.pad_trailing("Ciudad", 15) <>
                 String.pad_trailing("Movimientos", 15) <>
                 String.pad_trailing("Movimiento de mayor magnitud", 32) <>
                 "Profundidad promedio"

    separador = String.duplicate("-", 80)

    filas =
      Enum.map(datos_ciudades, fn %{ciudad: ciudad, stats: stats} ->
        col_ciudad = String.pad_trailing(ciudad.nombre, 15)
        col_movs = String.pad_trailing(Integer.to_string(stats.cantidad), 15)
        col_mayor = String.pad_trailing(stats.mayor_texto, 32)
        col_prom = stats.profundidad_promedio_texto

        col_ciudad <> col_movs <> col_mayor <> col_prom
      end)

    Enum.join([encabezado, separador | filas], "\n")
  end
end
