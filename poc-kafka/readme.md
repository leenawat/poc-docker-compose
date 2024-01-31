ref: https://www.baeldung.com/ops/kafka-new-topic-docker-compose


Creating a Kafka Topic
```
docker-compose exec kafka kafka-topics.sh --create --topic baeldung_linux --partitions 1 --replication-factor 1 --bootstrap-server kafka:9092
```

Consuming Messages
```
docker-compose exec kafka kafka-console-consumer.sh --topic baeldung_linux --from-beginning --bootstrap-server kafka:9092
```

Publishing message
```
docker-compose exec kafka kafka-console-producer.sh --topic baeldung_linux --broker-list kafka:9092
```