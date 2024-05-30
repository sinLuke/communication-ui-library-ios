//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCommunicationCommon

struct CallConfiguration {
    let groupId: UUID?
    let meetingLink: String?
    /* <MEETING_ID_LOCATOR> */
    let meetingId: String?
    let meetingPasscode: String?
    /* </MEETING_ID_LOCATOR> */
    let compositeCallType: CompositeCallType
    let credential: CommunicationTokenCredential
    let displayName: String?
    let diagnosticConfig: DiagnosticConfig
    /* <ROOMS_SUPPORT:7> */
    let roomId: String?
    let roomRoleHint: ParticipantRole?
    /* </ROOMS_SUPPORT> */
    init(locator: JoinLocator,
         credential: CommunicationTokenCredential,
         displayName: String? /* <ROOMS_SUPPORT> */ ,
         roleHint: ParticipantRole? /* </ROOMS_SUPPORT> */) {
        switch locator {
        case let .groupCall(groupId: groupId):
            self.groupId = groupId
            self.meetingLink = nil
            /* <MEETING_ID_LOCATOR> */
            self.meetingId = nil
            self.meetingPasscode = nil
            /* </MEETING_ID_LOCATOR> */
            /* <ROOMS_SUPPORT> */
            self.roomId = nil
            self.roomRoleHint = nil
            /* </ROOMS_SUPPORT> */
            self.compositeCallType = .groupCall
        case let .teamsMeeting(teamsLink: meetingLink):
            self.groupId = nil
            self.meetingLink = meetingLink
            /* <MEETING_ID_LOCATOR> */
            self.meetingId = nil
            self.meetingPasscode = nil
            /* </MEETING_ID_LOCATOR> */
            self.compositeCallType = .teamsMeeting
        /* <ROOMS_SUPPORT> */
            self.roomId = nil
            self.roomRoleHint = nil
        case let .teamsMeetingId(meetingId: meetingId, meetingPassword: meetingPasscode):
            self.groupId = nil
            self.meetingLink = nil
            /* <MEETING_ID_LOCATOR> */
            self.meetingId = meetingId
            self.meetingPasscode = meetingPasscode
            /* </MEETING_ID_LOCATOR> */
            self.compositeCallType = .teamsMeeting
        /* <ROOMS_SUPPORT> */
            self.roomId = nil
            self.roomRoleHint = nil
        case let .roomCall(roomId: roomId):
            self.roomId = roomId
            self.roomRoleHint = roleHint
            self.groupId = nil
            self.meetingLink = nil
            /* <MEETING_ID_LOCATOR> */
            self.meetingId = nil
            self.meetingPasscode = nil
            /* </MEETING_ID_LOCATOR> */
            self.compositeCallType = .roomsCall
        /* </ROOMS_SUPPORT> */
        }
        self.credential = credential
        self.displayName = displayName
        self.diagnosticConfig = DiagnosticConfig()
    }
}

enum CompositeCallType {
    case groupCall
    case teamsMeeting
    /* <ROOMS_SUPPORT:3> */ case roomsCall /* </ROOMS_SUPPORT:1> */
}
