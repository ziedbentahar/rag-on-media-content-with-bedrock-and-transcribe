# 🏗 Architecture Documentation

## 📖 Context
* **Goal of the Repository**: The repository is part of an application designed to facilitate media transcription and knowledge base querying. It provides a system for uploading media files, transcribing them, and storing the transcriptions in a knowledge base that can be queried. This application offers business value by automating the transcription process and enabling efficient retrieval of information from transcriptions.
* **Used Services and Libraries**:
  - **AWS Services**: AWS Lambda, AWS S3, AWS API Gateway, AWS CloudWatch, AWS IAM, AWS Transcribe, AWS Secrets Manager, AWS SQS, AWS Bedrock.
  - **Third-party Services**: Pinecone for vector storage.
  - **Libraries**: `aws-sdk` for various AWS services, `serde` for JSON serialization/deserialization, `nanoid` for generating unique IDs, `reqwest` for HTTP requests.

## 📖 Overview
* **Architecture Overview**: The architecture is serverless, leveraging AWS Lambda functions to handle different tasks such as media upload, transcription job initiation, handling successful transcriptions, and querying the knowledge base. The system uses AWS S3 for storage, AWS Transcribe for transcription services, and Pinecone for vector storage of transcriptions.
* **Component Interactions**:
  - **API Gateway**: Acts as the entry point for HTTP requests, routing them to the appropriate Lambda functions.
  - **Lambda Functions**: Handle specific tasks such as creating media upload links, starting transcription jobs, processing transcription results, and querying the knowledge base.
  - **S3 Buckets**: Store media files, metadata, and transcription results.
  - **Event-Driven Flows**: S3 events trigger Lambda functions to start transcription jobs, and CloudWatch events handle transcription success or failure.
* **Design Patterns and Architectural Decisions**:
  - **Serverless Architecture**: Utilizes AWS Lambda for scalable, event-driven processing.
  - **Event-Driven Architecture**: S3 and CloudWatch events trigger processing flows.
  - **Microservices**: Each Lambda function acts as a microservice with a specific responsibility.

## 🔹 Components

| Component                              | Description                                                                                   |
|----------------------------------------|-----------------------------------------------------------------------------------------------|
| `API Gateway`                          | Routes HTTP requests to the appropriate Lambda functions.                                     |
| `Lambda: create_media_upload_link`     | Generates presigned S3 URLs for media uploads and stores metadata.                            |
| `Lambda: start_transcription_job`      | Initiates transcription jobs using AWS Transcribe when media is uploaded to S3.               |
| `Lambda: handle_successful_transcription` | Processes successful transcription results and stores them in the knowledge base.             |
| `Lambda: query_knowledge_base`         | Handles queries to the knowledge base, retrieving and generating responses.                   |
| `S3 Buckets`                           | Store media files, metadata, and transcription results.                                       |
| `Pinecone`                             | Stores vector representations of transcriptions for efficient querying.                       |
| `AWS Transcribe`                       | Provides transcription services for media files.                                              |
| `AWS Bedrock`                          | Manages the knowledge base and handles ingestion and retrieval operations.                    |

## 🔄 Data Flow

| Data Flow Step                         | Description                                                                                   |
|----------------------------------------|-----------------------------------------------------------------------------------------------|
| Media Upload                           | User uploads media via a presigned S3 URL.                                                    |
| Transcription Job Initiation           | S3 event triggers `start_transcription_job` Lambda to initiate transcription.                  |
| Transcription Processing               | `handle_successful_transcription` Lambda processes transcription results and updates the knowledge base. |
| Knowledge Base Query                   | `query_knowledge_base` Lambda handles queries and retrieves information from the knowledge base. |

## 🔍 Mermaid Diagram

```mermaid
sequenceDiagram
    participant User
    participant API Gateway
    participant Lambda: create_media_upload_link
    participant S3
    participant Lambda: start_transcription_job
    participant AWS Transcribe
    participant Lambda: handle_successful_transcription
    participant Pinecone
    participant Lambda: query_knowledge_base

    User->>API Gateway: POST /media
    API Gateway->>Lambda: create_media_upload_link: Generate Upload Link
    Lambda: create_media_upload_link->>S3: Store Metadata
    User->>S3: Upload Media
    S3->>Lambda: start_transcription_job: Trigger on Upload
    Lambda: start_transcription_job->>AWS Transcribe: Start Transcription
    AWS Transcribe->>Lambda: handle_successful_transcription: Transcription Completed
    Lambda: handle_successful_transcription->>Pinecone: Store Transcription Vector
    User->>API Gateway: POST /query
    API Gateway->>Lambda: query_knowledge_base: Query Knowledge Base
    Lambda: query_knowledge_base->>Pinecone: Retrieve Information
    Lambda: query_knowledge_base->>User: Return Query Results
```

## 🧱 Technologies

| Technology            | Description                                                                                   |
|-----------------------|-----------------------------------------------------------------------------------------------|
| AWS Lambda            | Serverless compute service for running code in response to events.                            |
| AWS S3                | Object storage service used for storing media files and metadata.                             |
| AWS API Gateway       | Managed service for creating, publishing, and managing APIs.                                  |
| AWS Transcribe        | Automatic speech recognition service for transcribing audio files.                            |
| AWS Bedrock           | Service for managing knowledge bases and handling retrieval operations.                       |
| Pinecone              | Vector database for storing and querying vector representations of data.                      |
| Rust                  | Programming language used for implementing Lambda functions.                                  |
| `serde`               | Rust library for JSON serialization and deserialization.                                      |
| `nanoid`              | Rust library for generating unique IDs.                                                       |
| `reqwest`             | Rust library for making HTTP requests.                                                        |

## 📝 **Codebase Evaluation**

**Objective**: Analyze the provided codebase for technical debt, focusing on dependency & coupling, code complexity, and cloud anti-patterns.

- **Dependency & Coupling**: The codebase uses AWS SDKs extensively, which is appropriate for the serverless architecture. However, ensure that each Lambda function is as decoupled as possible to maintain modularity.
- **Code Complexity**: The use of Rust and its libraries like `serde` and `nanoid` is efficient. However, ensure that error handling is consistent and comprehensive across all functions.
- **Cloud Anti-patterns**: 
  - **Hardcoded Secrets**: Ensure that all sensitive information, such as API keys, is stored securely using AWS Secrets Manager.
  - **Inefficient Scaling**: The serverless architecture inherently scales, but monitor Lambda execution times and memory usage to optimize performance.
  - **Improper Error Handling**: Ensure that all potential errors, especially in network calls and AWS service interactions, are handled gracefully.

**Suggestions**:
- Refactor Lambda functions to ensure single responsibility and reduce interdependencies.
- Implement comprehensive logging and monitoring to track performance and errors.
- Regularly review IAM policies to ensure least privilege access.