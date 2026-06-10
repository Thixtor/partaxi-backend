# Usa la distribución optimizada y ligera de Python
FROM python:3.9-slim

# Crea una carpeta de trabajo dentro del contenedor
WORKDIR /app

# Copia tu lista de librerías
COPY requirements.txt .

# Instala las librerías
RUN pip install --no-cache-dir -r requirements.txt

# Copia todo el código de tu API a la carpeta de trabajo
COPY . .

# Expone el puerto lógico interno
EXPOSE 8000

# Comando para encender el servidor web
CMD ["uvicorn", "main.py", "--host", "0.0.0.0", "--port", "8000"]