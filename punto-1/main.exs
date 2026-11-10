# Punto 1: Observatorio Sismológico de la Universidad del Quindío
# Reporte Local de Movimientos Sísmicos

dir_base = __DIR__

Code.require_file("modelos.exs", dir_base)
Code.require_file("validador.exs", dir_base)
Code.require_file("lector.exs", dir_base)
Code.require_file("calculador.exs", dir_base)
Code.require_file("reporte.exs", dir_base)
Code.require_file("coordinador.exs", dir_base)

ruta_ciudades = Path.join(dir_base, "resources/ciudades.txt")
ruta_movimientos = Path.join(dir_base, "resources/movimientos.txt")
ruta_salida = Path.join(dir_base, "resources/reporte_sismos.txt")

IO.puts("================================================================================")
IO.puts("Iniciando generación de reporte sísmico local (Punto 1)...")
IO.puts("Leyendo archivos concurrentemente...")
IO.puts("================================================================================\n")

Coordinador.generar_reporte(ruta_ciudades, ruta_movimientos, ruta_salida)
