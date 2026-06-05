// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    // SectionID "topartist" → onFavArtists (the user's hearted favorites).
    // The historical filename keeps matching the SectionID; the human title
    // reflects what the data actually is.
    title: qsTr("Favorite Artists")
    cacheKey: "topartist"
    filterPlaceholder: qsTr("Filter artists")
    filterDebounceMs: 600

    Connections {
        target: tidalApi
        onFavArtists: section.addItem("artist", artist_info)
    }
}
