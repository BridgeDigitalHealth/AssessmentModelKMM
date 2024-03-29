package org.sagebionetworks.assessmentmodel

import org.sagebionetworks.assessmentmodel.resourcemanagement.AssetResourceInfo
import org.sagebionetworks.assessmentmodel.resourcemanagement.StandardResourceAssetType

/**
 * The [ImageInfo] is used to define a placeholder for an image. This could refer to a drawable object as defined by
 * the platform, a url, or the name of an embedded resource.
 */
interface ImageInfo : AssetResourceInfo, DrawableLayout {

    /**
     * A unique identifier that can be used to validate that the image shown in a reusable view is the same image as the
     * one fetched. This can also be used as the string value to fetch an image.
     */
    val imageName: String

    /**
     * A caption or label to display for the image in a localized string.
     */
    val label: String?

    /**
     * A boolean as to whether or not the icon should be tinted.
     */
    val tint: Boolean
        get() = false

    override val resourceAssetType: String?
        get() = StandardResourceAssetType.DRAWABLE

    override val resourceName: String
        get() = imageName
}

interface AnimatedImageInfo : ImageInfo {

    /**
     * The list of image names for the images to include in this animation.
     */
    val imageNames: List<String>

    /**
     * The animation duration for the image animation.
     */
    val animationDuration: Double

    /**
     * This is used to set how many times the animation should be repeated where `0` means infinite.
     */
    val animationRepeatCount: Int?
}

/**
 * The frame layout is a generic interface that can be extended to include descriptive layout for the drawable element
 * with which it is associated.  This may include size, placement hints, alignment, or other more complex descriptions
 * for the constraints that the image view should apply when rendering the image. This interface is intentionally
 * generic since each platform may model this differently in a manner that is logical for the given platform.
*/
interface DrawableLayout