import os
import time
import pika
import cv2
import mediapipe as mp
import numpy as np

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

def remove_bg(input_path, output_path):
    """Simple background remover using OpenCV grabCut."""
    image_path = input_path
    image = cv2.imread(image_path)
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Initialize Mediapipe selfie segmentation
    mp_selfie = mp.solutions.selfie_segmentation
    with mp_selfie.SelfieSegmentation(model_selection=1) as selfie_segmentation:
        result = selfie_segmentation.process(image_rgb)
        mask = result.segmentation_mask

    # Threshold the mask to get binary background mask
    condition = mask > 0.5  # True for person, False for background

    # Replace background with white
    bg_color = (255, 255, 255)
    bg_image = np.full(image.shape, bg_color, dtype=np.uint8)

    # Blend the images
    output_image = np.where(condition[..., None], image, bg_image)

    # Save result
    cv2.imwrite(output_path, output_image)

def process_image(ch, method, properties, body):
    filename = body.decode()
    input_path = os.path.join(UPLOAD_FOLDER, filename)
    output_path = os.path.join(OUTPUT_FOLDER, f"{filename}")

    print(f"[WORKER] Received task for {filename}")

    start_time = time.time()

    try:
        remove_bg(input_path, output_path)
        duration = time.time() - start_time
        print(f"[WORKER] ✅ Done processing in {duration:.2f}s → {output_path}")

        # Acknowledge message only after successful processing
        ch.basic_ack(delivery_tag=method.delivery_tag)

        with open("processing_metrics.prom", "a+") as f:
            f.write(f'image_processing_time_seconds{{filename="{filename}"}} {duration}\n')

    except Exception as e:
        print(f"[WORKER] ❌ Error processing {filename}: {e}")
        # Requeue failed image
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)


def main():
    connection = pika.BlockingConnection(connection_params)
    channel = connection.channel()
    channel.queue_declare(queue="image_tasks", durable=True)

    channel.basic_qos(prefetch_count=1)

    channel.basic_consume(queue="image_tasks", on_message_callback=process_image, auto_ack=False)

    print("[WORKER] Waiting for tasks. Press CTRL+C to exit.")
    channel.start_consuming()


if __name__ == "__main__":
    main()

