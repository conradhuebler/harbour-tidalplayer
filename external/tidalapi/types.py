# Copyright (C) 2023- The Tidalapi Developers

from enum import Enum
from typing import Any, Dict

JsonObj = Dict[str, Any]


def parse_iso_date(value):
    # Lazy import: keeps python-dateutil off the app-startup import path.
    import dateutil.parser

    return dateutil.parser.isoparse(value)


class AlbumOrder(Enum):
    Artist = "ARTIST"
    DateAdded = "DATE"
    Name = "NAME"
    ReleaseDate = "RELEASE_DATE"


class ArtistOrder(Enum):
    DateAdded = "DATE"
    Name = "NAME"


class ItemOrder(Enum):
    Album = "ALBUM"
    Artist = "ARTIST"
    Date = "DATE"
    Index = "INDEX"
    Length = "LENGTH"
    Name = "NAME"


class MixOrder(Enum):
    DateAdded = "DATE"
    MixType = "MIX_TYPE"
    Name = "NAME"


class PlaylistOrder(Enum):
    DateCreated = "DATE"
    Name = "NAME"


class VideoOrder(Enum):
    Artist = "ARTIST"
    DateAdded = "DATE"
    Name = "NAME"


class OrderDirection(Enum):
    Ascending = "ASC"
    Descending = "DESC"
