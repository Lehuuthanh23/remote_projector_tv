package com.example.play_box.model.command

enum class CommandEnum(val command: String) {
    GET_TIME_NOW("GET_TIMENOW"),
    RESTART_APP("RESTART_APP"),
    VIDEO_STOP("VIDEO_STOP"),
    VIDEO_PAUSE("VIDEO_PAUSE"),
    VIDEO_RESTART("VIDEO_RESTART"),
    VIDEO_FROMUSB("VIDEO_FROMUSB"),
    VIDEO_FROMCAMP("VIDEO_FROMCAMP"),
    DELETE_DEVICE("DELETE_DEVICE"),
    WAKE_UP_APP("WAKE_UP_APP"),
}