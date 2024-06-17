package com.example.play_box.model.camp

import com.google.gson.annotations.SerializedName

data class CampModel(
    @SerializedName("campaign_id")
    val campaignId: String,
    @SerializedName("campaign_name")
    val campaignName: String?,
    val status: String?,
    @SerializedName("video_id")
    val videoId: String?,
    @SerializedName("from_date")
    val fromDate: String?,
    @SerializedName("to_date")
    val toDate: String?,
    @SerializedName("from_time")
    val fromTime: String?,
    @SerializedName("to_time")
    val toTime: String?,
    @SerializedName("days_of_week")
    val daysOfWeek: String?,
    @SerializedName("video_type")
    val videoType: String?,
    @SerializedName("url_youtobe")
    val urlYoutube: String?,
    @SerializedName("url_usp")
    val urlUSP: String?,
    @SerializedName("computer_id")
    val computerId: String?,
    var listTimeRun: List<TimeRunModel>?
)

data class TimeRunModel(
    @SerializedName("id_run")
    val idRun: String?,
    @SerializedName("campaign_id")
    val campaignId: String?,
    @SerializedName("from_time")
    val fromTime: String,
    @SerializedName("to_time")
    val toTime: String
)