echo '{"@timestamp":"2025-08-26T08:00:00+07:00","level":"INFO","message":"Hello from manual test.log"}' >> logs/test2.log


touch logs/test2.log
echo '{"@timestamp":"2025-08-26T10:05:00+07:00","level":"ERROR","message":"Something went wrong"}' >> logs/test2.log

touch logs/user-service.log
echo '{ "timestamp": "2025-08-26T01:25:42.123Z", "level": "INFO", "service": "user-service", "traceId": "64f9a8b2c3d4e5f6", "message": "User created fail with ID: 12345", "logger": "com.example.service.UserService", "thread": "http-nio-8080-exec-1" }' >> logs/user-service.log



touch user-service.log
echo '{ "timestamp": "2025-08-26T02:54:42.123Z", "level": "INFO", "service": "user-service", "traceId": "64f9a8b2c3d4e5f6", "message": "User created fail with ID: 12345", "logger": "com.example.service.UserService", "thread": "http-nio-8080-exec-1" }' >> user-service.log