from fastapi import FastAPI

app = FastAPI(title="DevSecOps Demo API")

@app.get("/")
def read_root():
    return {"message": "¡Hola, pipeline DevSecOps!"}

@app.get("/health")
def health_check():
    return {"status": "ok"}