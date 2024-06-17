package com.example.play_box.model.user

import com.google.gson.annotations.SerializedName

class UserModel(
    @SerializedName("customer_id")
    val customerId: String? = null,
    @SerializedName("customer_name")
    val customerName: String? = null,
    val address: String? = null,
    @SerializedName("phone_number")
    var phoneNumber: String? = null,
    val email: String? = null,
    @SerializedName("date_of_birth")
    val dateOfBirth: String? = null,
    val sex: String? = null,
    @SerializedName("chu_tk")
    val chuTk: String? = null,
    val stk: String? = null,
    @SerializedName("nganhang")
    val nganHang: String? = null,
    @SerializedName("chinhanh")
    val chiNhanh: String? = null,
    var password: String? = null,
    @SerializedName("customer_token")
    val customerToken: String? = null
)