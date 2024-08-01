use serde::Deserialize;
use serde_valid::Validate;

#[derive(Default, Debug, Clone, PartialEq, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct Query {
    #[validate(min_length = 5)]
    pub input: String,
    #[validate(min_length = 5)]
    pub topic: String,
}
