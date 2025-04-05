import os
from google.cloud import storage

def hello_gcs(event, context):
    """
    Cloud Function que se activa cuando se sube un archivo a un bucket GCS.
    Lee el contenido del archivo y lo guarda procesado en la carpeta /processed.

    Args:
        event (dict): Información del evento GCS (nombre del bucket, nombre del archivo, etc.).
        context (google.cloud.functions.Context): Metadata del evento (ID, timestamp, etc.).
    """
    bucket_name = event['bucket']
    file_name = event['name']
    
    print(f"[INFO] Archivo recibido: {file_name} en bucket: {bucket_name}")
    
    # Cliente de GCS
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_name)
    
    # Leer contenido del archivo original
    content = blob.download_as_text()
    print("[DEBUG] Contenido del archivo:")
    print(content)
    
    # Procesar contenido (aquí puedes hacer más cosas)
    processed_content = f"Procesado: {content}"
    
    # Subir archivo procesado a carpeta /processed/
    output_path = f"processed/processed_{os.path.basename(file_name)}"
    output_blob = bucket.blob(output_path)
    output_blob.upload_from_string(processed_content)
    
    print(f"[INFO] Archivo procesado guardado como: {output_path}")
