# 🏗 Architecture Documentation

## 📖 Context
* **Goal of the Repository**: The repository is part of an application designed to facilitate media transcription and knowledge base querying. It provides a system for uploading media files, transcribing them, and storing the transcriptions in a knowledge base that can be queried. This application is valuable for businesses that need to manage and retrieve information from large volumes of audio or video content efficiently.
* **Used Services and Libraries**:
  - **AWS Services**: AWS Lambda, AWS S3, AWS API Gateway, AWS CloudWatch, AWS IAM, AWS Transcribe, AWS Secrets Manager, AWS SQS, AWS Bedrock.
  - **Third-party Services**: Pinecone for vector storage.
  - **Libraries**: `aws-sdk` for various AWS services, `serde` for JSON serialization/deserialization, `lambda_http` for handling HTTP requests in Lambda, `nanoid` for generating unique IDs.

## 📖 Overview
* **Architecture Overview**: The architecture is serverless, leveraging AWS Lambda functions to handle various tasks such as starting transcription jobs, handling successful transcriptions, creating media upload links, and querying the knowledge base. The system uses AWS S3 for storage, AWS Transcribe for transcription services, and Pinecone for vector storage of transcriptions. API Gateway is used to expose HTTP endpoints for client interactions.
* **Component Interactions**:
  - **API Gateway**: Routes HTTP requests to the appropriate Lambda functions.
  - **Lambda Functions**: Perform tasks such as creating presigned S3 URLs, starting transcription jobs, processing transcription results, and querying the knowledge base.
  - **S3 Buckets**: Store media files, transcription results, and metadata.
  - **Pinecone**: Stores vector representations of transcriptions for efficient querying.
  - **Event-Driven Flows**: S3 events trigger Lambda functions to start transcription jobs, and CloudWatch events handle transcription job completions.
* **Design Patterns and Architectural Decisions**:
  - **Serverless Architecture**: Utilizes AWS Lambda for scalable, event-driven processing.
  - **Event-Driven Architecture**: S3 and CloudWatch events trigger processing workflows.
  - **Microservices**: Each Lambda function acts as a microservice with a specific responsibility.

## 🔹 Components

| Component                              | Description                                                                                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------|
| `create_media_upload_link_lambda`      | Generates presigned S3 URLs for media uploads and stores metadata.                              |
| `start_transcription_job_lambda`       | Initiates transcription jobs when new media files are uploaded to S3.                           |
| `handle_successful_transcription_lambda` | Processes completed transcription jobs, stores results, and updates the knowledge base.         |
| `query_knowledge_base_lambda`          | Handles queries to the knowledge base, retrieving and generating responses based on stored data.|

## 🔄 Data Flow

| Data Flow Step                         | Description                                                                                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------|
| Media Upload                           | Client requests a presigned URL to upload media to S3.                                          |
| Transcription Job Start                | S3 event triggers Lambda to start a transcription job using AWS Transcribe.                     |
| Transcription Completion               | CloudWatch event triggers Lambda to process transcription results and update the knowledge base.|
| Knowledge Base Query                   | Client queries the knowledge base via API Gateway, which invokes a Lambda function to retrieve data.|

## 🔍 Mermaid Diagram

```mermaid
sequenceDiagram
    participant Client
    participant API Gateway
    participant Lambda: create_media_upload_link
    participant S3
    participant Lambda: start_transcription_job
    participant AWS Transcribe
    participant CloudWatch
    participant Lambda: handle_successful_transcription
    participant Pinecone
    participant Lambda: query_knowledge_base

    Client->>API Gateway: Request presigned URL
    API Gateway->>Lambda: create_media_upload_link
    Lambda->>S3: Store metadata
    Lambda-->>Client: Return presigned URL

    Client->>S3: Upload media file
    S3->>Lambda: start_transcription_job
    Lambda->>AWS Transcribe: Start transcription job

    AWS Transcribe->>CloudWatch: Transcription job completed
    CloudWatch->>Lambda: handle_successful_transcription
    Lambda->>S3: Store transcription result
    Lambda->>Pinecone: Update knowledge base

    Client->>API Gateway: Query knowledge base
    API Gateway->>Lambda: query_knowledge_base
    Lambda->>Pinecone: Retrieve data
    Lambda-->>Client: Return query result
```

## 🧱 Technologies

| Technology          | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| AWS Lambda          | Serverless compute service for running code in response to events.          |
| AWS S3              | Object storage service for storing media files and transcription results.   |
| AWS API Gateway     | Service for creating and managing APIs.                                     |
| AWS Transcribe      | Service for converting speech to text.                                      |
| Pinecone            | Vector database for storing and querying vector embeddings.                 |
| Rust                | Programming language used for implementing Lambda functions.                |

## 📝 **Codebase Evaluation**

**Objective**: Analyze the provided codebase for technical debt, focusing on dependency & coupling, code complexity, and cloud anti-patterns.

- **Dependency & Coupling**: The codebase is well-structured with clear separation of concerns across different Lambda functions. Each function has a specific role, reducing tight coupling.
- **Code Complexity**: The use of Rust and its strong type system helps manage complexity. However, the error handling could be improved by using more descriptive error messages and consistent error handling strategies.
- **Cloud Anti-patterns**: 
  - **Hardcoded Secrets**: The use of AWS Secrets Manager for storing API keys is a good practice, avoiding hardcoded secrets.
  - **Inefficient Scaling**: The serverless architecture inherently supports scaling, but monitoring and optimizing Lambda memory and timeout settings could further enhance performance.
  - **Improper Error Handling**: Ensure all potential errors are logged and handled gracefully, especially in network calls and AWS service interactions.

**Suggestions**:
- Refactor error handling to provide more context and use consistent patterns across functions.
- Review and optimize Lambda configurations (memory, timeout) based on usage patterns.
- Implement comprehensive logging and monitoring to identify and address performance bottlenecks.