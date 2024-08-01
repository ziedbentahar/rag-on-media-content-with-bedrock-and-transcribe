use serde::Deserialize;

#[derive(Default, Debug, Clone, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TranscriptionSuccessEvent {
    pub transcription_job: String,
}
