
+9
    }
    
    static var recentWorks: [Work] = []
    
    static func template(id: String) -> Template? {
        allTemplates.first(where: { $0.id == id })
    }
    
    static var quickCreateTemplates: [Template] {
        ["persona_card", "group_judge", "friend_vote", "truth_dare"]
            .compactMap { template(id: $0) }
    }
}

UserProfileStore.swift
