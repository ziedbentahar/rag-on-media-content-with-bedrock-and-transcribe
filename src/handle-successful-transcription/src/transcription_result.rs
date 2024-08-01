use serde::{Deserialize, Serialize};

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TranscriptionResult {
    pub job_name: String,
    pub account_id: String,
    pub status: String,
    pub results: Results,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Results {
    pub transcripts: Vec<Transcript>,
    #[serde(rename = "speaker_labels")]
    pub speaker_labels: SpeakerLabels,
    pub items: Vec<Item2>,
    #[serde(rename = "audio_segments")]
    pub audio_segments: Vec<AudioSegment>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Transcript {
    pub transcript: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SpeakerLabels {
    pub segments: Vec<Segment>,
    #[serde(rename = "channel_label")]
    pub channel_label: String,
    pub speakers: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Segment {
    #[serde(rename = "start_time")]
    pub start_time: String,
    #[serde(rename = "end_time")]
    pub end_time: String,
    #[serde(rename = "speaker_label")]
    pub speaker_label: String,
    pub items: Vec<Item>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Item {
    #[serde(rename = "speaker_label")]
    pub speaker_label: String,
    #[serde(rename = "start_time")]
    pub start_time: String,
    #[serde(rename = "end_time")]
    pub end_time: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Item2 {
    pub id: i64,
    #[serde(rename = "type")]
    pub type_field: String,
    pub alternatives: Vec<Alterna>,
    #[serde(rename = "start_time")]
    pub start_time: Option<String>,
    #[serde(rename = "end_time")]
    pub end_time: Option<String>,
    #[serde(rename = "speaker_label")]
    pub speaker_label: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Alterna {
    pub confidence: String,
    pub content: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AudioSegment {
    pub id: i64,
    pub transcript: String,
    #[serde(rename = "start_time")]
    pub start_time: String,
    #[serde(rename = "end_time")]
    pub end_time: String,
    #[serde(rename = "speaker_label")]
    pub speaker_label: String,
    pub items: Vec<i64>,
}
