# 🏗 Architecture Documentation

## 📖 Context
* **Goal of the Repository**: The repository is part of an application designed to facilitate media transcription and knowledge base querying. It provides a system for uploading media files, transcribing them, and storing the transcriptions in a knowledge base that can be queried. This application is valuable for businesses that need to manage and retrieve information from large volumes of audio or video content efficiently.
* **Notable Code Libraries and Services**:
  - **AWS Services**: Utilizes AWS Lambda for serverless functions, AWS S3 for storage, AWS Transcribe for transcription services, AWS API Gateway for API management, AWS CloudWatch for logging, AWS IAM for access management, AWS Secrets Manager for secure storage of API keys, and AWS SQS for message queuing.
  - **Pinecone**: Used for vector storage and retrieval, facilitating the knowledge base's vector search capabilities.
  - **Rust Libraries**: Includes `aws-sdk-s3`, `aws-sdk-transcribe`, `aws-sdk-bedrockagent`, `lambda_http`, `serde_json`, and `serde_valid` for various functionalities like HTTP handling, JSON serialization, and validation.

## 📖 Overview
* **Architecture Overview**: The architecture is serverless, leveraging AWS Lambda functions to handle different tasks such as media upload, transcription job initiation, handling successful transcriptions, and querying the knowledge base. The system uses AWS S3 for storing media files and transcriptions, and AWS Transcribe for converting media files into text. The transcriptions are stored in a Pinecone vector database, which is queried using AWS Bedrock for knowledge retrieval.
* **Component Interactions**:
  - **API Gateway**: Routes HTTP requests to the appropriate Lambda functions.
  - **Lambda Functions**: Handle tasks such as creating media upload links, starting transcription jobs, processing transcription results, and querying the knowledge base.
  - **S3 Buckets**: Store media files, metadata, and transcription results.
  - **Pinecone**: Stores vectorized transcription data for efficient retrieval.
  - **Event-Driven Flows**: S3 events trigger Lambda functions to start transcription jobs, and CloudWatch events handle transcription job completions.
* **Design Patterns and Architectural Decisions**:
  - **Serverless Architecture**: Utilizes AWS Lambda for scalable, event-driven processing.
  - **Event-Driven Architecture**: S3 and CloudWatch events trigger processing workflows.
  - **Microservices**: Each Lambda function acts as a microservice with a specific responsibility.

## 🔹 Components

| Component                              | Role                                                                                     | Interactions                                                                                   |
|----------------------------------------|------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| AWS Lambda Functions                   | Execute specific tasks such as media upload, transcription, and querying.                | Interact with S3, Transcribe, API Gateway, and Pinecone.                                      |
| AWS S3                                 | Stores media files, metadata, and transcription results.                                 | Trigger Lambda functions on object creation.                                                  |
| AWS Transcribe                         | Converts media files into text.                                                          | Initiated by Lambda functions to start transcription jobs.                                    |
| AWS API Gateway                        | Manages API requests and routes them to Lambda functions.                                | Provides HTTP endpoints for client interaction.                                               |
| Pinecone                               | Stores vectorized transcription data for efficient retrieval.                            | Used by Lambda functions to store and query transcription data.                               |
| AWS CloudWatch                         | Logs application activity and manages event rules for transcription job status changes.  | Monitors Lambda function execution and transcription job status.                              |
| AWS Secrets Manager                    | Securely stores API keys and other sensitive information.                                | Accessed by Lambda functions to retrieve necessary credentials.                               |
| AWS SQS                                | Handles message queuing for failed transcription jobs.                                   | Used as a dead-letter queue for handling transcription failures.                              |

## 🔄 Data Flow

| Data Flow Step                         | Description                                                                                 |
|----------------------------------------|---------------------------------------------------------------------------------------------|
| Media Upload                           | Client uploads media files via API Gateway, which triggers a Lambda function to generate a presigned S3 URL. |
| Transcription Job Initiation           | S3 event triggers a Lambda function to start a transcription job using AWS Transcribe.      |
| Transcription Completion               | CloudWatch event triggers a Lambda function to process the transcription result and store it in Pinecone. |
| Knowledge Base Query                   | Client queries the knowledge base via API Gateway, which triggers a Lambda function to retrieve data from Pinecone. |

## 🔍 Mermaid Diagram

```mermaid
sequenceDiagram
    participant Client
    participant API Gateway
    participant Lambda:CreateMediaUploadLink
    participant S3
    participant Lambda:StartTranscriptionJob
    participant Transcribe
    participant CloudWatch
    participant Lambda:HandleSuccessfulTranscription
    participant Pinecone
    participant Lambda:QueryKnowledgeBase

    Client->>API Gateway: POST /media
    API Gateway->>Lambda:CreateMediaUploadLink: Invoke
    Lambda:CreateMediaUploadLink->>S3: Generate presigned URL
    S3-->>Client: Return presigned URL
    Client->>S3: Upload media file
    S3->>Lambda:StartTranscriptionJob: Trigger on object creation
    Lambda:StartTranscriptionJob->>Transcribe: Start transcription job
    Transcribe->>CloudWatch: Emit transcription job status
    CloudWatch->>Lambda:HandleSuccessfulTranscription: Trigger on job completion
    Lambda:HandleSuccessfulTranscription->>Pinecone: Store transcription data
    Client->>API Gateway: POST /query
    API Gateway->>Lambda:QueryKnowledgeBase: Invoke
    Lambda:QueryKnowledgeBase->>Pinecone: Query data
    Pinecone-->>Lambda:QueryKnowledgeBase: Return results
    Lambda:QueryKnowledgeBase-->>Client: Return query results
```

## 🧱 Technologies

| Technology                  | Description                                                                 |
|-----------------------------|-----------------------------------------------------------------------------|
| AWS Lambda                  | Serverless compute service for running code in response to events.          |
| AWS S3                      | Object storage service for storing media files and transcriptions.          |
| AWS Transcribe              | Service for converting speech to text.                                      |
| AWS API Gateway             | Service for creating, publishing, and managing APIs.                        |
| AWS CloudWatch              | Monitoring and observability service for logging and event management.      |
| AWS Secrets Manager         | Service for managing secrets and sensitive information.                     |
| AWS SQS                     | Message queuing service for handling asynchronous communication.            |
| Pinecone                    | Vector database for storing and querying vectorized data.                   |
| Rust                        | Programming language used for implementing Lambda functions.                |

## 📝 **Codebase Evaluation**

**Objective**: Analyze the provided codebase for technical debt, focusing on dependency & coupling, code complexity, and cloud anti-patterns.

- **Dependency & Coupling**: The codebase is well-structured with clear separation of concerns across different Lambda functions. Each function has a specific role, reducing tight coupling. However, ensure that shared logic is abstracted into common modules to avoid code duplication.
- **Code Complexity**: The use of Rust and its libraries like `serde_json` and `serde_valid` helps maintain code readability and validation. However, consider breaking down complex functions into smaller, more manageable units to improve maintainability.
- **Cloud Anti-Patterns**: The use of environment variables for configuration is appropriate, but ensure that all sensitive information is stored securely in AWS Secrets Manager. Review IAM policies to ensure the principle of least privilege is followed, minimizing permissions to only what is necessary.

**Actionable Suggestions**:
- Refactor large functions into smaller, reusable components.
- Ensure all sensitive data is stored in AWS Secrets Manager and accessed securely.
- Review and tighten IAM policies to adhere to the principle of least privilege.
- Consider implementing automated tests to ensure code quality and reliability.