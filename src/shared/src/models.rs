use chrono::NaiveDate;
use serde::Deserialize;
use serde_valid::Validate;
use serde_valid::validation::Error;

#[derive(Default, Debug, Clone, PartialEq, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct MediaMetadata {
    #[validate(min_length = 5)]
    pub topic: String,
    #[validate(min_length = 5)]
    pub source_url: String,
    #[validate(custom = | v | validate_date_format(v))]
    pub date: String,
}

fn validate_date_format(date_str: &str) -> Result<(), serde_valid::validation::Error> {
    match NaiveDate::parse_from_str(date_str, "%Y-%m-%d") {
        Ok(_) => Ok(()),
        Err(_) => Err(Error::Custom(format!(
            "Invalid date format {}. Expected format is yyyy-MM-dd.",
            date_str
        ))),
    }
}
