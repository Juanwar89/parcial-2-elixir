defmodule Validador do
  @moduledoc """
  Módulo de validación de registros de ciudades y movimientos sísmicos.
  Aplica las reglas del enunciado:
  - Líneas vacías se ignoran.
  - Campos obligatorios no pueden ser vacíos.
  - Tipos numéricos válidos (habitantes > 0, profundidad >= 0.0).
  - Horas válidas del día (HH:MM:SS en rango 00:00:00 a 23:59:59).
  """

  alias Modelos.Ciudad
  alias Modelos.Movimiento

  @doc """
  Valida una línea del archivo de ciudades.
  Retorna:
  - `:ignorar` si la línea está vacía.
  - `{:ok, %Ciudad{}}` si es válida.
  - `{:error, motivo}` si es inválida (para ser rechazada).
  """
  def validar_ciudad_linea(linea) when is_binary(linea) do
    linea_limpia = String.trim(linea)

    if linea_limpia == "" do
      :ignorar
    else
      partes = String.split(linea_limpia, "@")

      case partes do
        [id_ciudad, nombre, habitantes_str] ->
          id_limpio = String.trim(id_ciudad)
          nombre_limpio = String.trim(nombre)

          with true <- id_limpio != "",
               true <- nombre_limpio != "",
               {:ok, habitantes} <- validar_entero_positivo(habitantes_str) do
            {:ok, %Ciudad{id_ciudad: id_limpio, nombre: nombre_limpio, numero_habitantes: habitantes}}
          else
            _ -> {:error, :datos_invalidos}
          end

        _ ->
          {:error, :formato_invalido}
      end
    end
  end

  @doc """
  Valida una línea del archivo de movimientos sísmicos.
  Retorna:
  - `:ignorar` si la línea está vacía.
  - `{:ok, %Movimiento{}}` si es válida.
  - `{:error, motivo}` si es inválida (para ser rechazada).
  """
  def validar_movimiento_linea(linea) when is_binary(linea) do
    linea_limpia = String.trim(linea)

    if linea_limpia == "" do
      :ignorar
    else
      partes = String.split(linea_limpia, "@")

      case partes do
        [codigo, id_ciudad, hora_inicio, hora_final, mag_str, prof_str] ->
          cod_limpio = String.trim(codigo)
          id_c_limpio = String.trim(id_ciudad)

          with true <- cod_limpio != "",
               true <- id_c_limpio != "",
               {:ok, h_ini} <- validar_hora(hora_inicio),
               {:ok, h_fin} <- validar_hora(hora_final),
               {:ok, magnitud} <- validar_decimal(mag_str),
               {:ok, profundidad} <- validar_profundidad(prof_str) do
            {:ok,
             %Movimiento{
               codigo: cod_limpio,
               id_ciudad: id_c_limpio,
               hora_inicio: h_ini,
               hora_final: h_fin,
               magnitud: magnitud,
               profundidad: profundidad
             }}
          else
            _ -> {:error, :datos_invalidos}
          end

        _ ->
          {:error, :formato_invalido}
      end
    end
  end

  @doc """
  Valida un entero estrictamente mayor que cero.
  """
  def validar_entero_positivo(cadena) when is_binary(cadena) do
    cadena = String.trim(cadena)

    case Integer.parse(cadena) do
      {num, ""} when num > 0 -> {:ok, num}
      _ -> {:error, :entero_no_positivo}
    end
  end

  @doc """
  Valida un número decimal (puede provenir de formato float o entero).
  """
  def validar_decimal(cadena) when is_binary(cadena) do
    cadena = String.trim(cadena)

    case Float.parse(cadena) do
      {val, ""} ->
        {:ok, val}

      _ ->
        case Integer.parse(cadena) do
          {val, ""} -> {:ok, val * 1.0}
          _ -> {:error, :decimal_invalido}
        end
    end
  end

  @doc """
  Valida la profundidad: número decimal mayor o igual a cero.
  """
  def validar_profundidad(cadena) when is_binary(cadena) do
    case validar_decimal(cadena) do
      {:ok, val} when val >= 0.0 -> {:ok, val}
      _ -> {:error, :profundidad_invalida}
    end
  end

  @doc """
  Valida una hora del día en formato HH:MM:SS (00 <= HH <= 23, 00 <= MM <= 59, 00 <= SS <= 59).
  """
  def validar_hora(cadena) when is_binary(cadena) do
    cadena = String.trim(cadena)

    case String.split(cadena, ":") do
      [hh_str, mm_str, ss_str]
      when byte_size(hh_str) == 2 and byte_size(mm_str) == 2 and byte_size(ss_str) == 2 ->
        with {hh, ""} <- Integer.parse(hh_str),
             {mm, ""} <- Integer.parse(mm_str),
             {ss, ""} <- Integer.parse(ss_str),
             true <- hh in 0..23 and mm in 0..59 and ss in 0..59 do
          {:ok, cadena}
        else
          _ -> {:error, :hora_fuera_de_rango}
        end

      _ ->
        {:error, :formato_hora_invalido}
    end
  end
end
