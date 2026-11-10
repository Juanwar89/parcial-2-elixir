defmodule Calculador do
  @moduledoc """
  Módulo de cálculo y procesamiento de estadísticas sismológicas.
  Implementa:
  - Filtrado de movimientos con idCiudad inexistente (sumándolos a rechazados).
  - Recursividad explícita para calcular en un único recorrido:
    * Cantidad de movimientos.
    * Movimiento de mayor magnitud (ante empate, el primero).
    * Suma de profundidades y cálculo de promedio con 2 decimales.
  """

  @doc """
  Filtra los movimientos sísmicos asegurando que su id_ciudad pertenezca
  al catálogo de ciudades válidas.
  Los movimientos huérfanos se excluyen y se suman al contador de rechazados
  del archivo de movimientos.
  """
  def filtrar_movimientos_por_ciudades(movimientos, ciudades, rechazados_inicial) do
    ids_validos = MapSet.new(ciudades, fn c -> c.id_ciudad end)
    filtrar_movimientos_rec(movimientos, ids_validos, [], rechazados_inicial)
  end

  defp filtrar_movimientos_rec([], _ids_validos, validos_acc, rechazados_acc) do
    {Enum.reverse(validos_acc), rechazados_acc}
  end

  defp filtrar_movimientos_rec([mov | resto], ids_validos, validos_acc, rechazados_acc) do
    if MapSet.member?(ids_validos, mov.id_ciudad) do
      filtrar_movimientos_rec(resto, ids_validos, [mov | validos_acc], rechazados_acc)
    else
      # Movimiento rechazado por idCiudad inexistente en catálogo
      filtrar_movimientos_rec(resto, ids_validos, validos_acc, rechazados_acc + 1)
    end
  end

  @doc """
  Calcula las estadísticas de los movimientos de una ciudad mediante recursividad explícita
  en un único recorrido de la lista.
  """
  def calcular_estadisticas_movimientos(movimientos) when is_list(movimientos) do
    calcular_recursivo(movimientos, 0, nil, 0.0)
  end

  # Caso base cuando la ciudad no tiene movimientos (cantidad == 0)
  defp calcular_recursivo([], 0, nil, _suma_profundidades) do
    %{
      tiene_movimientos: false,
      cantidad: 0,
      mov_mayor: nil,
      mayor_texto: "No aplica",
      profundidad_promedio_num: nil,
      profundidad_promedio_texto: "No aplica"
    }
  end

  # Caso base al finalizar el recorrido de una lista con al menos un movimiento
  defp calcular_recursivo([], cantidad, mayor_mov, suma_profundidades) do
    promedio = suma_profundidades / cantidad
    promedio_texto = :erlang.float_to_binary(promedio, [decimals: 2]) <> " km"
    mayor_texto = "#{mayor_mov.codigo} · #{formatear_decimal(mayor_mov.magnitud)}"

    %{
      tiene_movimientos: true,
      cantidad: cantidad,
      mov_mayor: mayor_mov,
      mayor_texto: mayor_texto,
      profundidad_promedio_num: promedio,
      profundidad_promedio_texto: promedio_texto
    }
  end

  # Paso recursivo: procesa el elemento de la cabeza y avanza con la cola
  defp calcular_recursivo([mov | resto], cantidad, mayor_mov, suma_profundidades) do
    nuevo_mayor =
      case mayor_mov do
        nil ->
          mov

        _ ->
          # Solo actualiza si la magnitud es estrictamente mayor (>).
          # Así, si varios tienen la misma magnitud máxima, se conserva el primero.
          if mov.magnitud > mayor_mov.magnitud do
            mov
          else
            mayor_mov
          end
      end

    calcular_recursivo(
      resto,
      cantidad + 1,
      nuevo_mayor,
      suma_profundidades + mov.profundidad
    )
  end

  @doc """
  Genera la lista de datos procesados para cada ciudad del catálogo.
  """
  def procesar_datos_ciudades(ciudades, movimientos) do
    movs_por_ciudad = Enum.group_by(movimientos, fn m -> m.id_ciudad end)

    Enum.map(ciudades, fn ciudad ->
      movs_de_ciudad = Map.get(movs_por_ciudad, ciudad.id_ciudad, [])
      stats = calcular_estadisticas_movimientos(movs_de_ciudad)

      %{
        ciudad: ciudad,
        movimientos: movs_de_ciudad,
        stats: stats
      }
    end)
  end

  @doc """
  Formatea un decimal asegurando una cifra decimal si termina en entero.
  """
  def formatear_decimal(val) when is_float(val) do
    :erlang.float_to_binary(val, [decimals: 1])
  end

  def formatear_decimal(val) when is_integer(val) do
    :erlang.float_to_binary(val * 1.0, [decimals: 1])
  end
end
