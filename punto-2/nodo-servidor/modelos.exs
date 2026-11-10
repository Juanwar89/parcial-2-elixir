defmodule Modelos.Ciudad do
  @moduledoc """
  Representa una ciudad del catálogo sismológico.
  - id_ciudad: Identificador único de la ciudad (String).
  - nombre: Nombre de la ciudad (String).
  - numero_habitantes: Número de habitantes, entero mayor que cero (Integer).
  """
  @enforce_keys [:id_ciudad, :nombre, :numero_habitantes]
  defstruct [:id_ciudad, :nombre, :numero_habitantes]
end

defmodule Modelos.Movimiento do
  @moduledoc """
  Representa un movimiento sísmico registrado.
  - codigo: Identificador único del movimiento (String).
  - id_ciudad: Identificador de la ciudad asociada (String).
  - hora_inicio: Hora de inicio en formato HH:MM:SS (String).
  - hora_final: Hora de finalización en formato HH:MM:SS (String).
  - magnitud: Magnitud del movimiento, número decimal (Float).
  - profundidad: Profundidad en km, número mayor o igual a cero (Float).
  """
  @enforce_keys [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
  defstruct [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
end
