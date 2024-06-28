package com.example.play_box.model.command

import com.google.gson.annotations.SerializedName

data class CommandModel(
    @SerializedName("cmd_id")
    val cmdId: String? = null,
    @SerializedName("cmd_code")
    val cmdCode: String? = null,
    @SerializedName("commit_time")
    val commitTime: String? = null,
    val content: String? = null,
    @SerializedName("is_imme")
    val isImme: String? = null,
    @SerializedName("return_time")
    val returnTime: String? = null,
    @SerializedName("return_value")
    val returnValue: String? = null,
    val sn: String? = null,
    val sync: String? = null,
    val done: String? = null,
    @SerializedName("second_wait")
    val secondWait: String? = null,
)