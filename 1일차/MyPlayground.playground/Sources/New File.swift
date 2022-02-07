// MARK: - New
   
   /// New count
   ///
   public func newCount(contains: (key: Expression<String?>, value: String)? = nil) -> Int {
       
       do {
           // Query
           // SELECT count(*) FROM new LEFT JOIN family on new.family_name = family.family_name WHERE available_ios = 1 AND deprecated = 0
           let query = self.newTable
               .join(.leftOuter, self.familyTable, on: self.newTable[VLContentDBColumn.new_familyName_ex] == self.familyTable[VLContentDBColumn.fml_name_ex])
               .filter(VLContentDBColumn.fml_availableiOS_ex == true)
               .filter(VLContentDBColumn.fml_deprecatediOS_ex == false)
           
           return try self.database.scalar(query.count)
           
       } catch {
           
           print("Function: \(#function), line: \(#line)")
           print(error)
           return 0
       }
   }
   
   /// New List
   
   /// 최신 콘텐츠 List를 반환한다.
   ///
   /// - Returns: List
   public func newList(contains: (key: Expression<String?>, value: String)? = nil) -> [SQLite.Row] {
       
       do {
           // Query
           // SELECT * FROM new LEFT JOIN family ON new.family_name = family.family_name WHERE family.available_ios = 1 AND family.deprecated = 0 ORDER BY new.ROWID DESC
           var query = self.newTable
               .join(.leftOuter, self.familyTable, on: self.newTable[VLContentDBColumn.new_familyName_ex] == self.familyTable[VLContentDBColumn.fml_name_ex])
           query = self.filterFamilyQuery(query: query)
           if let filter = contains {
               query = query.filter(filter.key.like("%\(filter.value)%"))
           }
           query = query.order(self.newTable[SQLite.rowid].asc)
           
           return Array(try self.database.prepare(query))
           
       } catch {
           
           print("Function: \(#function), line: \(#line)")
           print(error)
           return []
       }
   }
   
   /// Index에 해당하는 New를 반환한다.
   ///
   /// - Parameter index: Index
   /// - Returns: New content
   public func new(index: Int, contains: (key: Expression<String?>, value: String)? = nil) -> SQLite.Row? {
       
       do {
           // Query
           // SELECT *, FROM new LEFT JOIN family ON new.family_name = family.family_name WHERE family.available_ios = 1 AND family.deprecated = 0 ORDER BY new.ROWID DESC LIMIT 1 OFFSET \(index)
           var query = self.newTable
               .join(.leftOuter, self.familyTable, on: self.newTable[VLContentDBColumn.new_familyName_ex] == self.familyTable[VLContentDBColumn.fml_name_ex])
           query = self.filterFamilyQuery(query: query)
           if let filter = contains {
               query = query.filter(filter.key.like("%\(filter.value)%"))
           }
           query = query.order(self.newTable[SQLite.rowid].asc)
               .limit(1, offset: index)
           
           for row in try self.database.prepare(query) {
               return row
           }
       } catch {
           
           print("Function: \(#function), line: \(#line)")
           print(error)
       }
       
       return nil
   }
