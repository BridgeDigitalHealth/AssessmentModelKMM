package org.sagebionetworks.assessmentmodel

import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import org.sagebionetworks.assessmentmodel.navigation.Direction
import org.sagebionetworks.assessmentmodel.survey.AnswerType

/**
 * A [Result] is any data result that should be included with an [Assessment]. The base level interface only has an
 * [identifier] and does not include any other properties. The [identifier] in this case may be either the
 * [ResultMapElement.resultIdentifier] *or* the [ResultMapElement.identifier] if the result identifier is undefined.
 *
 * TODO: syoung 01/10/2020 figure out a clean-ish way to encode the result and include in the base interface. In Swift, the `RSDResult` conforms to the `Encodable` protocol so it can be encoded to a JSON dictionary. Is there a Kotlin equivalent?
 *
 */
interface Result {
    fun copyResult(identifier: String = this.identifier) : Result

    /**
     * The identifier for the result. This identifier maps to the [ResultMapElement.resultIdentifier] for an associated
     * [Assessment] element.
     */
    val identifier: String

    /**
     * The start date timestamp for the result.
     */
    var startDateTime: Instant

    /**
     * The end date timestamp for the result.
     */
    var endDateTime: Instant?
}

fun MutableSet<Result>.copyResults() = map { it.copyResult() }.toMutableSet()
fun MutableList<Result>.copyResults() = map { it.copyResult() }.toMutableList()

/**
 * A [CollectionResult] is used to describe the output of a [Section], [FormStep], or [Assessment].
 */
interface CollectionResult : Result {
    override fun copyResult(identifier: String) : CollectionResult

    /**
     * The [inputResults] is a set that contains results that are recorded in parallel to the user-facing node
     * path. This can be the async results of a sensor recorder, a response to a service call, or the results from a
     * form where all the fields are displayed together and the results do not represent a linear path. The results
     * within this set should each have a unique identifier.
     */
    var inputResults: MutableSet<Result>
}

/**
 * The [BranchNodeResult] is the result created for a given level of navigation of a node tree. The
 * [pathHistoryResults] is additive where each time a node is traversed, it is added to the list.
 */
interface BranchNodeResult : CollectionResult {
    override fun copyResult(identifier: String) : BranchNodeResult

    /**
     * The [pathHistoryResults] includes the history of the [Node] results that were traversed as a part of running an
     * [Assessment]. This will only include a subset that is the path defined at this level of the overall [Assessment]
     * hierarchy.
     */
    var pathHistoryResults: MutableList<Result>

    /**
     * The path traversed by this branch.
     */
    val path: MutableList<PathMarker>
}

@Serializable
data class PathMarker(val identifier: String, val direction: Direction)

/**
 * An [AssessmentResult] is the top-level [Result] for an [Assessment].
 */
interface AssessmentResult : BranchNodeResult {
    override fun copyResult(identifier: String) : AssessmentResult

    /**
     * A unique identifier for this run of the assessment. This property is defined as readwrite to allow the
     * controller for the task to set this on the [AssessmentResult] children included in this run.
     */
    var runUUIDString: String

    /**
     * A unique identifier for an [Assessment] model associated with this result. This is explicitly
     * included so that the [identifier] can be associated as per the needs of the developers and
     * to allow for changes to the API that are not important to the researcher.
     */
    val assessmentIdentifier: String?

    /**
     * A unique identifier for a schema associated with this result. This is explicitly included so
     * that the [identifier] can be associated as per the needs of the developers and to allow for
     * changes to the API that are not important to the researcher.
     */
    val schemaIdentifier: String?

    /**
     * The [versionString] may be a semantic version, timestamp, or sequential revision integer. This should map to the
     * [Assessment.versionString].
     */
    val versionString: String?
}

/**
 * An [AnswerResult] is used to hold a serializable answer to a question or measurement.
 */
interface AnswerResult : Result {
    override fun copyResult(identifier: String) : AnswerResult

    /**
     * Optional property for defining additional information about the answer expected for this result.
     */
    val answerType: AnswerType?

    /**
     * The answer held by this result.
     */
    var jsonValue: JsonElement?

    /**
     * The text of the question displayed to the participant.
     */
    val questionText: String?
}

/**
 * A [FileResult] is used to hold a result that is written to a file.
 */
interface FileResult : Result {

    /**
     * The name of the file to be written to the archive.
     */
    val filename: String

    /**
     * The path to the file-based result.
     */
    val path: String?

    /**
     * The MIME content type of the result.
     * - example: `"application/json"`
     */
    val contentType: String?

    /**
     * The url for the json schema that defined the content if this file has a content type of "application/json".
     */
    val jsonSchema: String?
}

/**
 * A [Result] that is to be included as a JSON file in the archive.
 */
interface JsonFileArchivableResult : Result {

    fun getJsonArchivableFile(stepPath: String) : JsonArchivableFile
}

data class JsonArchivableFile(
    /**
     * The name of the file to be written.
     */
    val filename: String,

    /**
     * The JSON string to be included as a file in the result archive.
     */
    val json: String,


    /**
     * The url for the json schema that defined the content of this json".
     */
    val jsonSchema: String?
)

