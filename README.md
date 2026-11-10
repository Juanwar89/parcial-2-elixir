# Observatorio Sismológico de la Universidad del Quindío
## Programación 3 — Parcial II

**Institución:** Universidad del Quindío  
**Programa:** Ingeniería de Sistemas y Computación  
**Asignatura:** Programación 3  
**Lenguaje:** Elixir (Erlang/OTP)

---

## 1. Organización del Repositorio

El proyecto se encuentra organizado en carpetas independientes para cada punto, cumpliendo de manera estricta con la estructura solicitada en las especificaciones del examen:

```text
parcial-2-elixir/
├── README.md
├── punto-1/
│   ├── modelos.exs                   # Definición de structs %Ciudad{} y %Movimiento{}
│   ├── validador.exs                 # Validaciones de formato, tipos, horas y valores numéricos
│   ├── lector.exs                    # Lectura recursiva y conteo de registros rechazados
│   ├── calculador.exs                # Filtrado de huérfanos y recursividad explícita en un solo recorrido
│   ├── reporte.exs                   # Formateo visual del reporte detallado y resumen general
│   ├── coordinador.exs               # Concurrencia con spawn/send/receive y control de errores
│   ├── main.exs                      # Script ejecutable principal del Punto 1
│   └── resources/
│       ├── ciudades.txt              # Archivo de entrada con las ciudades del catálogo
│       ├── movimientos.txt           # Archivo de entrada con los movimientos sísmicos
│       └── reporte_sismos.txt        # Archivo generado con el reporte final
└── punto-2/
    ├── nodo-cliente/
    │   └── cliente.exs               # Nodo cliente distribuido (:servicio_respuesta)
    └── nodo-servidor/
        ├── modelos.exs               # Structs del dominio (reutilizados del Punto 1)
        ├── validador.exs             # Validaciones (reutilizadas del Punto 1)
        ├── lector.exs                # Lectura de archivos (reutilizada del Punto 1)
        ├── calculador.exs            # Cálculos sismológicos (reutilizados del Punto 1)
        ├── reporte.exs               # Formateador de texto (reutilizado del Punto 1)
        ├── servidor.exs              # Nodo servidor concurrente distribuido (:servicio_sismos)
        └── resources/
            ├── ciudades.txt          # Archivo de ciudades para consultas en caliente
            └── movimientos.txt       # Archivo de movimientos para consultas en caliente
```

---

## 2. Punto 1 — Reporte Local de Sismos

### 2.1. Descripción de la Solución
El programa local genera un reporte consolidado de los movimientos sísmicos registrados por ciudad:
1. **Concurrencia (`spawn`, `send`, `receive`)**: Un proceso coordinador inicia concurrentemente dos procesos trabajadores (uno para `ciudades.txt` y otro para `movimientos.txt`) **antes** de esperar sus respuestas. El coordinador recibe los mensajes en cualquier orden.
2. **Validación robusta y conteo de rechazados**:
   - Las líneas vacías son ignoradas automáticamente.
   - Se validan campos obligatorios no vacíos, número de habitantes entero mayor a cero, horas del día válidas (`00:00:00` a `23:59:59`), magnitudes convertibles a decimal y profundidades mayores o iguales a cero (`>= 0.0`).
   - Se rechaza todo movimiento sísmico cuyo `idCiudad` no corresponda a una ciudad válida del catálogo.
   - Cada línea rechazada se contabiliza una sola vez y se discrimina por archivo al final del reporte.
3. **Recursividad explícita en un único recorrido**: Para calcular la cantidad de movimientos, el movimiento con mayor magnitud (preservando el primero en aparecer en caso de empate) y la suma acumulada de profundidades, se utiliza una función con recursión de cola explícita (`[cabeza | cola]`), calculando a partir de la suma y la cantidad el promedio con dos cifras decimales.
4. **Conservación y manejo de errores**:
   - Si alguno de los archivos de entrada no existe o falla su lectura, el sistema informa en consola qué archivo generó el error y **conserva intacto el reporte anterior**.
   - Cada generación exitosa sobrescribe `resources/reporte_sismos.txt`.
   - Si ocurre un fallo de escritura, se informa el error en la consola.

### 2.2. Archivos de Entrada y Salida
- **Archivos de entrada:**
  - `punto-1/resources/ciudades.txt`
  - `punto-1/resources/movimientos.txt`
- **Archivo de salida generado:**
  - `punto-1/resources/reporte_sismos.txt`

### 2.3. Instrucciones de Ejecución
Abra una terminal en la carpeta del Punto 1 y ejecute:

```bash
cd punto-1
elixir main.exs
```

*(También es posible ejecutarlo directamente desde la raíz del repositorio con `elixir punto-1/main.exs`).*

### 2.4. Resultado Obtenido con los Datos de Ejemplo
Tanto en la consola como en `resources/reporte_sismos.txt` se obtiene el resultado esperado:

```text
================================================================================
           OBSERVATORIO SISMOLÓGICO DE LA UNIVERSIDAD DEL QUINDÍO
                        REPORTE GENERAL DE SISMOS
================================================================================

DETALLE POR CIUDAD:
--------------------------------------------------------------------------------
Ciudad: Armenia (ID: C01)
Número de habitantes: 304314
Movimientos registrados:
  * Código: S001 | Inicio: 08:15:02 | Fin: 08:15:18 | Magnitud: 3.4 | Profundidad: 18.0 km
  * Código: S003 | Inicio: 11:42:00 | Fin: 11:42:12 | Magnitud: 2.8 | Profundidad: 10.0 km
Cantidad total de movimientos: 2
Movimiento de mayor magnitud: S001 · 3.4
Profundidad promedio: 14.00 km

Ciudad: Calarcá (ID: C02)
Número de habitantes: 78684
Movimientos registrados:
  * Código: S002 | Inicio: 09:30:10 | Fin: 09:30:29 | Magnitud: 4.1 | Profundidad: 25.0 km
Cantidad total de movimientos: 1
Movimiento de mayor magnitud: S002 · 4.1
Profundidad promedio: 25.00 km

Ciudad: Circasia (ID: C03)
Número de habitantes: 30941
Movimientos registrados:
  Sin movimientos registrados
Cantidad total de movimientos: 0
Movimiento de mayor magnitud: No aplica
Profundidad promedio: No aplica

--------------------------------------------------------------------------------
RESUMEN GENERAL:
--------------------------------------------------------------------------------
Ciudad         Movimientos    Movimiento de mayor magnitud    Profundidad promedio
--------------------------------------------------------------------------------
Armenia        2              S001 · 3.4                      14.00 km
Calarcá        1              S002 · 4.1                      25.00 km
Circasia       0              No aplica                       No aplica

--------------------------------------------------------------------------------
REGISTROS RECHAZADOS:
- Archivo de ciudades (ciudades.txt): 0 registro(s) rechazado(s)
- Archivo de movimientos (movimientos.txt): 0 registro(s) rechazado(s)
================================================================================
```

---

## 3. Punto 2 — Consulta de Reportes Sísmicos entre Nodos

### 3.1. Descripción de la Solución
Permite la consulta distribuida de reportes sísmicos entre dos nodos de Elixir que se comunican mediante paso de mensajes (`send` y `receive`) sobre la red Erlang:

- **Nodo Servidor (`:servicio_sismos`)**:
  - Se registra con el nombre atómico `:servicio_sismos`.
  - Ante cada petición recibida, **lee concurrentemente las versiones actuales de ambos archivos**, reflejando en tiempo real cualquier cambio en los datos sin necesidad de reiniciar el servidor.
  - Reutiliza exactamente los mismos structs, validaciones y funciones de cálculo del Punto 1.
  - Responde en el mismo orden en que recibe las solicitudes.
  - Si una ciudad existe y no tiene movimientos, indica `«Sin movimientos registrados»`, `0` y `«No aplica»`.
  - Si el identificador no existe en el catálogo, responde `«La ciudad no está registrada»`.
  - Al recibir `:fin`, envía la confirmación `:fin` y **continúa esperando solicitudes mediante una llamada recursiva**, garantizando que el servidor permanece disponible para clientes posteriores.
- **Nodo Cliente (`:servicio_respuesta`)**:
  - Registra el proceso con el nombre `:servicio_respuesta`.
  - Intenta la conexión mediante `Node.connect/1`. Si la conexión falla, emite un mensaje descriptivo y termina.
  - Envía las 5 solicitudes en el orden riguroso exigido:
    1. Reporte de ciudad con movimientos (`"C01"`).
    2. Reporte de ciudad sin movimientos (`"C03"`).
    3. Reporte de ciudad con identificador inexistente (`"C99"`).
    4. Reporte general (`:reporte_general`).
    5. Mensaje de fin (`:fin`).
  - Recibe y muestra las respuestas en consola de manera **recursiva** hasta recibir `:fin`.

### 3.2. Configuración de Nodos y Cookies
Ambos nodos deben ejecutarse con un nombre corto (`--sname`) y **la misma cookie de autenticación distribuida** (`--cookie`).

| Componente | Carpeta | Nombre de Nodo sugerido | Cookie | Proceso registrado |
|---|---|---|---|---|
| **Servidor** | `punto-2/nodo-servidor` | `servidor` | `sismos_secret` | `:servicio_sismos` |
| **Cliente** | `punto-2/nodo-cliente` | `cliente` | `sismos_secret` | `:servicio_respuesta` |

### 3.3. Instrucciones de Ejecución Paso a Paso

#### Paso 1: Iniciar el Nodo Servidor (Terminal 1)
Abra la primera terminal, navegue a la carpeta del servidor e inícielo:

```bash
cd punto-2/nodo-servidor
elixir --sname servidor --cookie sismos_secret servidor.exs
```

Verá en consola:
```text
================================================================================
             OBSERVATORIO SISMOLÓGICO - NODO SERVIDOR ACTIVO
================================================================================
Nodo Servidor:  servidor@<tu_host>
Cookie activa:  sismos_secret
Proceso:        :servicio_sismos
Estado:         Esperando solicitudes de clientes...
```

#### Paso 2: Iniciar el Nodo Cliente (Terminal 2)
Abra una segunda terminal independiente, navegue a la carpeta del cliente y ejecútelo:

```bash
cd punto-2/nodo-cliente
elixir --sname cliente --cookie sismos_secret cliente.exs
```

*(Nota: El cliente detecta automáticamente el nombre completo del servidor en la misma máquina. Si se ejecuta en máquinas distintas, puede indicarse el nodo como argumento: `elixir --sname cliente --cookie sismos_secret cliente.exs servidor@nombre_maquina`).*

---

## 4. Verificación del Punto 2

### 4.1. Identificadores Utilizados en las Pruebas
Para la verificación estricta de las 4 consultas solicitadas en el enunciado se utilizaron:
1. **Ciudad con movimientos registrados:** ID `"C01"` (Armenia, con 2 movimientos: `S001` y `S003`).
2. **Ciudad sin movimientos registrados:** ID `"C03"` (Circasia, 0 movimientos, «No aplica»).
3. **Ciudad con identificador inexistente:** ID `"C99"` (Respuesta: `«La ciudad no está registrada»`).
4. **Reporte general:** Solicitud `:reporte_general` (Detalle de todas las ciudades, tabla resumen y conteo de rechazados).
5. **Finalización:** Mensaje `:fin` (Confirmación `:fin`).

### 4.2. Ejecución Consecutiva (Demostración de Disponibilidad del Servidor)
Para comprobar que el servidor no muere tras recibir `:fin` y continúa atendiendo solicitudes recursivamente:

1. Deje la **Terminal 1** (servidor) abierta y en ejecución.
2. En la **Terminal 2**, ejecute el cliente por primera vez:
   ```bash
   elixir --sname cliente --cookie sismos_secret cliente.exs
   ```
   *El cliente mostrará las cuatro respuestas en orden y finalizará al recibir `:fin`.*
3. En la misma **Terminal 2**, vuelva a ejecutar el cliente inmediatamente:
   ```bash
   elixir --sname cliente --cookie sismos_secret cliente.exs
   ```
   *El cliente se conecta de nuevo exitosamente al mismo servidor, vuelve a mostrar las 4 respuestas completas y termina limpiamente con `:fin`.*
4. En la **Terminal 1** se observará que el servidor atendió ambas sesiones consecutivas sin interrupciones.

---

## 5. Reflexión sobre el Uso de Inteligencia Artificial

> Cumplimiento de la sección obligatoria requerida en los criterios de entrega y sustentación.

### 1. Herramientas y Agentes
Se utilizó el asistente **Antigravity (Google DeepMind)** con el modelo **Gemini 3.8 Flash** en modo avanzado de razonamiento y asistencia de programación en parejas. Se empleó en tareas puntuales como:
- Estructuración de la arquitectura de procesos (`spawn`, `send`, `receive`) y diseño de los módulos según principios de alta cohesión.
- Definición de casos de prueba de borde para las validaciones sintácticas y semánticas de los archivos de entrada (líneas vacías, horas inválidas, registros huérfanos).
- Verificación de compatibilidad de tipos numéricos y patrones en Erlang/OTP 27 y 28.

### 2. Caso Decisivo
- **Situación:** En el Punto 1 se exigía estrictamente: *"Implementar recursividad explícita para recorrer los movimientos de cada ciudad y calcular, en un mismo recorrido, la cantidad de movimientos, el de mayor magnitud y la suma de profundidades. A partir de la suma y la cantidad se calculará el promedio."*
- **Interacción y Respuesta:** Inicialmente se consideró utilizar funciones de orden superior de la biblioteca estándar como `Enum.reduce/3` o `Enum.max_by/2`. La IA recomendó no usarlas, señalando que la rúbrica evalúa explícitamente el dominio de la **recursión pura funcional** mediante descomposición de listas con acumuladores (`[cabeza | cola]`).
- **Verificación y Adaptación:** Se implementó una función privada con recursión de cola (`calcular_recursivo/4`) que en un solo paso acumula el contador, compara estrictamente (`>`) la magnitud para preservar el primer registro en caso de empate y suma las profundidades. Al llegar a la lista vacía `[]`, calcula el promedio dividiendo la suma entre el contador. Esta solución se probó unitariamente con ciudades de 0, 1, 2 y múltiples sismos empatados, demostrando exactitud absoluta sin funciones auxiliares de biblioteca.

### 3. Idea Diferente de la Clase
- **Sugerencia:** En lugar de hacer que el proceso coordinador esperara primero obligatoriamente al trabajador de ciudades y luego al trabajador de movimientos (lo que generaría un acoplamiento secuencial innecesario), se sugirió diseñar la función receptora con una tupla de estado `{res_ciudades, res_movimientos}` dentro de un `receive` recursivo.
- **Aporte y Aprendizaje:** Esta técnica permite recibir los mensajes en **cualquier orden de llegada** sin importar cuál trabajador termine primero (si ciudades o movimientos). Al recibir el primer mensaje se preserva su valor y se continúa esperando el restante; una vez ambos están presentes, se retorna la tupla con los dos resultados. Esto garantiza concurrencia genuina sin orden preestablecido, cumpliendo al 100% el requisito: *"El coordinador deberá aceptar las respuestas en cualquier orden"*.

### 4. Conclusiones
- **Qué se comprende por sí solo:**
  - El modelo de actores de Erlang/Elixir: creación de procesos livianos con `spawn`, paso de mensajes asíncrono con `send` y consumo selectivo con `receive`.
  - La comunicación distribuida entre nodos de red utilizando nombres registrados con `Process.register/2`, conexión con `Node.connect/1` y seguridad mediante cookies comunes.
  - La inmutabilidad de los datos y el manejo de registros mediante structs con `@enforce_keys`.
- **Qué costó mayor esfuerzo:**
  - Garantizar la robustez en sistemas Windows cuando existen restricciones de permisos o procesos en segundo plano para el demonio `epmd` (Erlang Port Mapper Daemon). Se aprendió que `epmd` gestiona el mapeo de nombres de nodo a puertos TCP locales y debe estar disponible para que los nodos puedan resolverse.
- **Qué se cambiaría en un siguiente proyecto:**
  - Empaquetar la solución utilizando un proyecto `Mix` con pruebas automatizadas (`ExUnit`) y supervisores (`Supervisor` y `GenServer`) para dotar a los procesos de tolerancia a fallos y reinicio automático en caso de caída inesperada.

---

## 6. Guía Rápida para la Sustentación Oral (Preguntas Clave del Docente)

Si durante la sustentación el docente solicita explicaciones o modificaciones en vivo:

1. **¿Dónde está la recursividad explícita?**
   - En [punto-1/calculador.exs](file:///c:/Users/juanc/OneDrive/Documentos/Parcial2Programacion3/punto-1/calculador.exs#L41-L98) en la función privada `calcular_recursivo/4`.
   - Se muestra cómo recorre `[mov | resto]`, acumulando `cantidad + 1`, seleccionando el mayor con `mov.magnitud > mayor_mov.magnitud` y acumulando `suma_profundidades + mov.profundidad`.

2. **¿Cómo se asegura que las respuestas del coordinador se aceptan en cualquier orden?**
   - En [punto-1/coordinador.exs](file:///c:/Users/juanc/OneDrive/Documentos/Parcial2Programacion3/punto-1/coordinador.exs#L71-L91) en `esperar_trabajadores/2`.
   - Si llega `{:archivo_ciudades, res}` primero, guarda ese resultado y espera `{:archivo_movimientos, res}`, y viceversa.

3. **¿Cómo se conservan los datos si falla la lectura de un archivo?**
   - En el `case {res_ciudades, res_movimientos}` de [coordinador.exs](file:///c:/Users/juanc/OneDrive/Documentos/Parcial2Programacion3/punto-1/coordinador.exs#L35-L53).
   - Si alguna tupla es `{:error, ...}`, imprime el mensaje de error indicando cuál archivo falló y retorna de inmediato sin escribir en el archivo de reporte.

4. **¿Por qué el servidor del Punto 2 no se apaga al responder `:fin`?**
   - En [punto-2/nodo-servidor/servidor.exs](file:///c:/Users/juanc/OneDrive/Documentos/Parcial2Programacion3/punto-2/nodo-servidor/servidor.exs#L55-L60).
   - Al hacer matching de `{destino_respuesta, :fin}`, envía `send(destino_respuesta, :fin)` y acto seguido realiza la llamada recursiva `bucle_servicio(ruta_ciudades, ruta_movimientos)`.
