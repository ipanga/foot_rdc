package com.tootiyesolutions.footrdc

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/**
 * FootRDC's own native ad layout on Android (`footrdc_native_ad.xml`), used instead of the plugin's medium template.
 * The template registers its store/advertiser text as an asset and then hides it when an ad has a star rating, which
 * the SDK validator reports as « Not all asset views lie inside the native ad view ». Here an asset is registered only
 * when it is shown, and every asset is a child of the NativeAdView.
 */
class FootrdcNativeAdFactory(private val inflater: LayoutInflater) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val view = inflater.inflate(R.layout.footrdc_native_ad, null) as NativeAdView

        val media = view.findViewById<MediaView>(R.id.fr_media)
        view.mediaView = media

        val headline = view.findViewById<TextView>(R.id.fr_headline)
        headline.text = nativeAd.headline
        view.headlineView = headline

        val body = view.findViewById<TextView>(R.id.fr_body)
        if (nativeAd.body.isNullOrBlank()) {
            body.visibility = View.GONE
        } else {
            body.text = nativeAd.body
            view.bodyView = body
        }

        val cta = view.findViewById<Button>(R.id.fr_cta)
        if (nativeAd.callToAction.isNullOrBlank()) {
            cta.visibility = View.GONE
        } else {
            cta.text = nativeAd.callToAction
            view.callToActionView = cta
        }

        val icon = view.findViewById<ImageView>(R.id.fr_icon)
        val drawable = nativeAd.icon?.drawable
        if (drawable == null) {
            icon.visibility = View.GONE
        } else {
            icon.setImageDrawable(drawable)
            view.iconView = icon
        }

        // One of: star rating, store, advertiser, or nothing. Only the shown one is registered.
        val stars = view.findViewById<RatingBar>(R.id.fr_stars)
        val secondary = view.findViewById<TextView>(R.id.fr_secondary)
        val rating = nativeAd.starRating
        when {
            rating != null && rating > 0 -> {
                stars.rating = rating.toFloat()
                view.starRatingView = stars
                secondary.visibility = View.GONE
            }
            !nativeAd.store.isNullOrBlank() && nativeAd.advertiser.isNullOrBlank() -> {
                stars.visibility = View.GONE
                secondary.text = nativeAd.store
                view.storeView = secondary
            }
            !nativeAd.advertiser.isNullOrBlank() -> {
                stars.visibility = View.GONE
                secondary.text = nativeAd.advertiser
                view.advertiserView = secondary
            }
            else -> {
                stars.visibility = View.GONE
                secondary.visibility = View.GONE
            }
        }

        view.setNativeAd(nativeAd)
        return view
    }
}
