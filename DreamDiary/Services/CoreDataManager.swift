import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DreamDiary")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if mainContext.hasChanges {
            do {
                try mainContext.save()
            } catch {
                let nserror = error as NSError
                print("Error saving Core Data context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // CoreDataManager.swift dosyasına aşağıdaki metodu ekleyin

    func fetchDreamsByTag(_ tag: String) -> [Dream] {
        let context = mainContext
        let fetchRequest: NSFetchRequest<DreamEntity> = DreamEntity.fetchRequest()
        
        // NSPredicate ile etiketleri içeren rüyaları bulma
        // Not: Bu, basitleştirilmiş bir yaklaşımdır. Gerçek uygulamada daha karmaşık olabilir.
        fetchRequest.predicate = NSPredicate(format: "ANY tags CONTAINS[cd] %@", tag)
        
        do {
            let dreamEntities = try context.fetch(fetchRequest)
            return dreamEntities.compactMap { convertToDreamModel($0) }
        } catch {
            print("Error fetching dreams by tag: \(error)")
            return []
        }
    }
    
    // MARK: - Rüya CRUD İşlemleri
    
    func saveDream(_ dream: Dream) {
        let context = mainContext
        
        // Eğer aynı ID ile kayıt varsa güncelle, yoksa yeni kayıt oluştur
        let fetchRequest: NSFetchRequest<DreamEntity> = DreamEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dream.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            let dreamEntity: DreamEntity
            
            if let existingDream = results.first {
                dreamEntity = existingDream
            } else {
                dreamEntity = DreamEntity(context: context)
                dreamEntity.id = dream.id
            }
            
            // Özellikleri güncelle
            dreamEntity.title = dream.title
            dreamEntity.content = dream.content
            dreamEntity.date = dream.date
            dreamEntity.mood = dream.mood.rawValue
            dreamEntity.tags = dream.tags as NSArray
            dreamEntity.imagePrompt = dream.imagePrompt
            dreamEntity.generatedImageURL = dream.generatedImageURL
            
            if let analysis = dream.analysis {
                dreamEntity.analysisThemes = analysis.themes as NSArray
                dreamEntity.analysisInterpretation = analysis.interpretation
                dreamEntity.analysisEmotionalTone = analysis.emotionalTone
                dreamEntity.analysisRecurringElements = analysis.recurringElements as NSArray
                dreamEntity.analysisPsychologicalPerspective = analysis.psychologicalPerspective
            }
            
            saveContext()
            
        } catch {
            print("Error saving dream: \(error)")
        }
    }
    
    func fetchAllDreams() -> [Dream] {
        let context = mainContext
        let fetchRequest: NSFetchRequest<DreamEntity> = DreamEntity.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let dreamEntities = try context.fetch(fetchRequest)
            return dreamEntities.compactMap { convertToDreamModel($0) }
        } catch {
            print("Error fetching dreams: \(error)")
            return []
        }
    }
    
    func deleteDream(id: UUID) {
        let context = mainContext
        let fetchRequest: NSFetchRequest<DreamEntity> = DreamEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let dreamToDelete = results.first {
                context.delete(dreamToDelete)
                saveContext()
            }
        } catch {
            print("Error deleting dream: \(error)")
        }
    }
    
    // MARK: - Yardımcı Metotlar
    
    private func convertToDreamModel(_ entity: DreamEntity) -> Dream? {
        guard let id = entity.id,
              let title = entity.title,
              let content = entity.content,
              let date = entity.date,
              let moodString = entity.mood,
              let mood = Dream.DreamMood(rawValue: moodString),
              let tagsArray = entity.tags as? [String] else {
            return nil
        }
        
        var dream = Dream(
            id: id,
            title: title,
            content: content,
            date: date,
            mood: mood,
            tags: tagsArray
        )
        
        dream.imagePrompt = entity.imagePrompt
        dream.generatedImageURL = entity.generatedImageURL
        
        // Analiz bilgilerini doldur
        if let themesArray = entity.analysisThemes as? [String],
           let interpretation = entity.analysisInterpretation,
           let emotionalTone = entity.analysisEmotionalTone,
           let recurringElementsArray = entity.analysisRecurringElements as? [String],
           let psychologicalPerspective = entity.analysisPsychologicalPerspective {
            
            let analysis = DreamAnalysis(
                themes: themesArray,
                interpretation: interpretation,
                emotionalTone: emotionalTone,
                recurringElements: recurringElementsArray,
                psychologicalPerspective: psychologicalPerspective
            )
            
            dream.analysis = analysis
        }
        
        return dream
    }
}
