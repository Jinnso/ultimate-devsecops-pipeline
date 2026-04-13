# ==========================================
# ETAPA 1: Constructor (Builder)
# Su único propósito es descargar y compilar dependencias
# ==========================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Si tuvieras dependencias complejas (como psycopg2 para PostgreSQL o librerías criptográficas), 
# aquí instalarías los compiladores del sistema:
# RUN apt-get update && apt-get install -y --no-install-recommends gcc build-essential

COPY requirements.txt .

# En lugar de instalar, le decimos a pip que construya "wheels" (paquetes precompilados)
# y los guarde en la carpeta /app/wheels
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


# ==========================================
# ETAPA 2: Producción (Runner)
# Es la imagen final limpia y segura que irá a Kubernetes
# ==========================================
FROM python:3.11-slim

WORKDIR /app

# Actualizar paquetes del sistema operativo para mitigar vulnerabilidades OS
RUN apt-get update && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/* 
# Eliminar Optimizaciones de Python

# Optimizaciones de Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 1. Crear el usuario sin privilegios por seguridad
RUN adduser --disabled-password --gecos '' appuser

# 2. Copiar SOLO los archivos compilados de la etapa "builder"
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .

# 3. Actualizar las herramientas base de Python y luego instalar nuestras dependencias
RUN pip install --no-cache-dir --upgrade pip setuptools \
    && pip install --no-cache /wheels/*

# 4. Copiar el código fuente de nuestra aplicación
COPY main.py .

# 5. Entregar la propiedad de la carpeta al usuario seguro
RUN chown -R appuser:appuser /app

# 6. Cambiar a ese usuario
USER appuser

# 7. Exponer el puerto
EXPOSE 8000

# 8. Comando de inicio
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]