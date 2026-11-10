defmodule Lector do
  @moduledoc """
  Módulo encargado de la lectura y procesamiento inicial de archivos.
  Lee los archivos del disco y utiliza recursividad para procesar las líneas,
  separando registros válidos de registros rechazados.
  """

  @doc """
  Lee y procesa el archivo de ciudades.
  Retorna:
  - `{:ok, {ciudades_validas, rechazados_conteo}}`
  - `{:error, {ruta, motivo}}`
  """
  def leer_archivo_ciudades(ruta) do
    case File.read(ruta) do
      {:ok, contenido} ->
        lineas = String.split(contenido, ["\r\n", "\n"])
        {ciudades, rechazados} = procesar_lineas_ciudades_rec(lineas, [], 0)
        {:ok, {ciudades, rechazados}}

      {:error, motivo} ->
        {:error, {ruta, motivo}}
    end
  end

  @doc """
  Lee y procesa el archivo de movimientos sísmicos.
  Retorna:
  - `{:ok, {movimientos_validos, rechazados_conteo}}`
  - `{:error, {ruta, motivo}}`
  """
  def leer_archivo_movimientos(ruta) do
    case File.read(ruta) do
      {:ok, contenido} ->
        lineas = String.split(contenido, ["\r\n", "\n"])
        {movimientos, rechazados} = procesar_lineas_movimientos_rec(lineas, [], 0)
        {:ok, {movimientos, rechazados}}

      {:error, motivo} ->
        {:error, {ruta, motivo}}
    end
  end

  # --- Recursividad explícita para procesar líneas de ciudades ---

  defp procesar_lineas_ciudades_rec([], validas, rechazados) do
    {Enum.reverse(validas), rechazados}
  end

  defp procesar_lineas_ciudades_rec([linea | resto], validas, rechazados) do
    case Validador.validar_ciudad_linea(linea) do
      :ignorar ->
        procesar_lineas_ciudades_rec(resto, validas, rechazados)

      {:ok, ciudad} ->
        procesar_lineas_ciudades_rec(resto, [ciudad | validas], rechazados)

      {:error, _motivo} ->
        procesar_lineas_ciudades_rec(resto, validas, rechazados + 1)
    end
  end

  # --- Recursividad explícita para procesar líneas de movimientos ---

  defp procesar_lineas_movimientos_rec([], validas, rechazados) do
    {Enum.reverse(validas), rechazados}
  end

  defp procesar_lineas_movimientos_rec([linea | resto], validas, rechazados) do
    case Validador.validar_movimiento_linea(linea) do
      :ignorar ->
        procesar_lineas_movimientos_rec(resto, validas, rechazados)

      {:ok, movimiento} ->
        procesar_lineas_movimientos_rec(resto, [movimiento | validas], rechazados)

      {:error, _motivo} ->
        procesar_lineas_movimientos_rec(resto, validas, rechazados + 1)
    end
  end
end
