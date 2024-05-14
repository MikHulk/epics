from djelm.flags import (
    Flags,
    ListFlag,
    StringFlag,
    ObjectFlag,
    NullableFlag,
    IntFlag,
)

key = "frontendstory-djelm-Story"

StoryFlags = Flags(
    ObjectFlag(
        {
            "story": ObjectFlag(
                {
                    "id": IntFlag(),
                    "pubDate": StringFlag(),
                    "title": StringFlag(),
                    "description": StringFlag(),
                    "status": StringFlag(),
                    "assignedTo": NullableFlag(StringFlag()),
                    "assignedToFullname": NullableFlag(StringFlag()),
                    "epic": ObjectFlag(
                        {
                            "title": StringFlag(),
                            "id": IntFlag(),
                            "url": StringFlag(),
                            "owner": StringFlag(),
                        }
                    )
                }
            ),
            "logoutUrl": StringFlag(),
            "csrfToken": StringFlag(),
            "username": StringFlag(),
        }
    )
)
