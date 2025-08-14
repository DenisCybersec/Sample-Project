from flask import Flask, request, render_template, send_from_directory, redirect, url_for
import pika, os, uuid

UPLOAD_FOLDER = "/app/uploads"
OUTPUT_FOLDER = "/app/outputs"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

connection_params = pika.ConnectionParameters(
        host=os.getenv("RABBITMQ_HOST", "localhost"),
        port=int(os.getenv("RABBITMQ_PORT", 5672)),
        credentials=pika.PlainCredentials(
            username=os.getenv("RABBITMQ_USER", "guest"),
            password=os.getenv("RABBITMQ_PASSWORD", "guest")
        )
    )

app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
app.config["OUTPUT_FOLDER"] = OUTPUT_FOLDER

def send_to_queue(file_id):
    """Send task info to RabbitMQ."""
    connection = pika.BlockingConnection(connection_params)
    channel = connection.channel()
    channel.queue_declare(queue="image_tasks", durable=True)

    # Send file id
    message = f"{file_id}"
    channel.basic_publish(
        exchange="",
        routing_key="image_tasks",
        body=message.encode(),
        properties=pika.BasicProperties(delivery_mode=2)
    )
    connection.close()

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/upload", methods=["POST"])
def upload():
    file = request.files["image"]
    if not file:
        return "No file uploaded", 400
    
    # Generate unique ID
    file_id = str(uuid.uuid4())
    extension = os.path.splitext(file.filename)[1]
    unique_filename = f"{file_id}{extension}"
    
    # Save file to uploads
    file_path = os.path.join(app.config["UPLOAD_FOLDER"], unique_filename)
    file.save(file_path)
    file.close()

    # Send job to queue
    send_to_queue(unique_filename)

    return redirect(url_for("result", file_id=file_id, ext=extension))

@app.route("/result/<file_id>")
def result(file_id):
    # Check if processed file exists
    processed_files = [f for f in os.listdir(app.config["OUTPUT_FOLDER"]) if f.startswith(file_id)]
    if processed_files:
        return render_template("result.html", filename=processed_files[0])
    else:
        return f"<h2>Processing...</h2><meta http-equiv='refresh' content='2'>"

@app.route("/outputs/<filename>")
def outputs(filename):
    return send_from_directory(app.config["OUTPUT_FOLDER"], filename)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

