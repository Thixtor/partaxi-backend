from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"mensaje": "Backend de ParTaxí operativo y listo para asignar servicios"}