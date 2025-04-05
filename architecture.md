# 🏗 Architecture Documentation

## 📖 Context
* **Goal of the Repository**: The repository is part of an application designed to facilitate media transcription and knowledge base querying. It provides a system for uploading media files, transcribing them, and storing the transcriptions in a knowledge base for further querying. This application offers business value by automating the transcription process and enabling efficient retrieval of information from transcriptions.
* **Notable Code Libraries and Services**:
  - **AWS Services**: Utilizes AWS Lambda for serverless functions, AWS S3 for storage, AWS Transcribe for transcription services, AWS API Gateway for API management, AWS CloudWatch for logging, AWS IAM for access control, AWS Secrets Manager for managing sensitive information, and AWS SQS for message queuing.
  - **Pinecone**: Used for vector storage and retrieval in the knowledge base.
  - **Rust Libraries**: Includes `aws-sdk-s3`, `aws-sdk-transcribe`, `aws-sdk-bedrockagent`, `lambda_http`, `serde_json`, and `serde_valid`.

## 📖 Overview
* **Architecture Overview**: The architecture is serverless, leveraging AWS Lambda functions to handle various tasks such as media upload, transcription job initiation, handling successful transcriptions, and querying the knowledge base. The system uses AWS S3 for storing media files and transcriptions, and AWS Transcribe for converting media files into text. The transcriptions are stored in a Pinecone vector database for efficient querying.
* **Component Interactions**:
  - Media files are uploaded to an S3 bucket, triggering a Lambda function to start a transcription job.
  - Transcription results are processed and stored in a knowledge base.
  - The knowledge base can be queried via an API Gateway, which invokes a Lambda function to retrieve and generate responses based on the stored transcriptions.
* **Design Patterns and Architectural Decisions**:
  - **Event-Driven Architecture**: Utilizes S3 events to trigger transcription jobs and CloudWatch events to handle transcription success or failure.
  - **Serverless Architecture**: Employs AWS Lambda for executing code in response to events, reducing the need for server management.
  - **Microservices**: Each Lambda function represents a microservice handling a specific task.

## 🔹 Components
| Component                              | Role                                                                                     | Interactions                                                                                   |
|----------------------------------------|------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| AWS Lambda Functions                   | Execute code in response to events (e.g., media upload, transcription completion).        | Interact with S3, Transcribe, API Gateway, and other AWS services.                            |
| AWS S3                                 | Stores media files and transcriptions.                                                   | Triggers Lambda functions on object creation.                                                 |
| AWS Transcribe                         | Converts media files into text.                                                          | Invoked by Lambda functions to start transcription jobs.                                      |
| AWS API Gateway                        | Manages API requests for querying the knowledge base.                                    | Routes requests to Lambda functions.                                                          |
| Pinecone                               | Stores and retrieves vectorized transcription data.                                      | Used by Lambda functions to store and query knowledge base data.                              |
| AWS CloudWatch                         | Provides logging and monitoring for the application.                                     | Logs events and metrics from Lambda functions and API Gateway.                                |
| AWS Secrets Manager                    | Manages sensitive information such as API keys.                                          | Accessed by Lambda functions to retrieve secrets.                                             |
| AWS SQS                                | Handles message queuing for failed transcription jobs.                                   | Used by CloudWatch events to send messages to a dead-letter queue.                            |

## 🔄 Data Flow
| Data Flow Step                         | Description                                                                                 |
|----------------------------------------|---------------------------------------------------------------------------------------------|
| Media Upload                           | Media files are uploaded to an S3 bucket, triggering a Lambda function to start transcription. |
| Transcription Job                      | The Lambda function initiates a transcription job using AWS Transcribe.                      |
| Transcription Completion               | Upon completion, a CloudWatch event triggers a Lambda function to process the transcription. |
| Knowledge Base Storage                 | The processed transcription is stored in a Pinecone vector database.                         |
| Querying                               | API Gateway routes query requests to a Lambda function, which retrieves data from Pinecone.  |

## 🔍 Mermaid Diagram
```mermaid
sequenceDiagram
    participant User
    participant API Gateway
    participant Lambda: Create Media Upload Link
    participant S3: Media Bucket
    participant Lambda: Start Transcription Job
    participant Transcribe
    participant CloudWatch
    participant Lambda: Handle Successful Transcription
    participant Pinecone
    participant Lambda: Query Knowledge Base

    User->>API Gateway: POST /media
    API Gateway->>Lambda: Create Media Upload Link
    Lambda->>S3: Store Metadata
    Lambda->>User: Return Upload URL
    User->>S3: Upload Media File
    S3->>Lambda: Start Transcription Job
    Lambda->>Transcribe: Start Job
    Transcribe->>CloudWatch: Job Completed
    CloudWatch->>Lambda: Handle Successful Transcription
    Lambda->>Pinecone: Store Transcription
    User->>API Gateway: POST /query
    API Gateway->>Lambda: Query Knowledge Base
    Lambda->>Pinecone: Retrieve Data
    Lambda->>User: Return Query Result
```

## 🧱 Technologies
| Technology                             | Description                                                                                 |
|----------------------------------------|---------------------------------------------------------------------------------------------|
| Rust                                   | Programming language used for Lambda function implementation.                               |
| AWS Lambda                             | Serverless compute service for running code in response to events.                          |
| AWS S3                                 | Object storage service for storing media files and transcriptions.                          |
| AWS Transcribe                         | Service for converting media files into text.                                               |
| AWS API Gateway                        | Service for creating, deploying, and managing APIs.                                         |
| Pinecone                               | Vector database for storing and querying transcription data.                                |
| AWS CloudWatch                         | Monitoring and logging service for AWS resources.                                           |
| AWS Secrets Manager                    | Service for managing sensitive information such as API keys.                                |
| AWS SQS                                | Message queuing service for handling failed transcription jobs.                             |

## 📝 **Codebase Evaluation**
* **Dependency & Coupling**: The codebase effectively uses AWS services, but there is a potential for tight coupling between Lambda functions and specific AWS services. Consider abstracting service interactions to reduce direct dependencies.
* **Code Complexity**: The use of Rust and its libraries is appropriate, but the complexity of handling errors and asynchronous operations could be improved with more modular code and error handling strategies.
* **Cloud Anti-Patterns**: No hardcoded secrets are present, as AWS Secrets Manager is used. However, ensure that IAM roles and policies are as restrictive as possible to follow the principle of least privilege.
* **Suggestions**:
  - Refactor Lambda functions to separate concerns and improve modularity.
  - Implement comprehensive error handling and logging to capture and manage exceptions effectively.
  - Review IAM policies to ensure they are not overly permissive and adhere to best practices.