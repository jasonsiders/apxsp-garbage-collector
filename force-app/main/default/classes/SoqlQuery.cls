global inherited sharing virtual class SoqlQuery implements IQuery {
    @TestVisible Set<String> fields = new Set<String>{'Id'};
    @TestVisible SObjectType targetObject;
    @TestVisible List<QueryFilter> filters = new List<QueryFilter>();
    @TestVisible QuerySort orderBy;
    @TestVisible List<String> queryTags = new List<String>(); 
    @TestVisible Integer queryLimit; 
    @TestVisible String filterLogic; 
    
    global SoqlQuery(SObjectType targetObject) {
        this.setTargetSObject(targetObject); 
    }
    
    // **** Running a Query **** // 
    global virtual List<SObject> run() {
        // Run the current query object through the database
        String soql = this.getQueryString(); 
        return Database.query(soql); 
    }

    global String getQueryString() {
        // Output the current SoqlQuery object as a SOQL Query string
        // SELECT {fields} FROM {targetObject} {WHERE filters} {ORDER BY orderBy} {LIMIT limit} {queryTags}
        String template = 'SELECT {0} FROM {1}{2}{3}{4}{5}';
        return String.format(template, new String[]{
            String.join(new List<String>(this.fields), ', '),
            String.valueOf(this.targetObject),
            this.getWhereClause(),
            this.getSpecialTags(),
            this.getOrderByClause(),
            this.getLimitClause()
        });
    }

    // **** Building a Query **** //
    global SoqlQuery setTargetSObject(SObjectType targetObject) {
        this.targetObject = targetObject; 
        return this; 
    }

    global SoqlQuery addFields(List<SObjectField> fields) {
        List<String> fieldStrings = new List<String>();
        for (SObjectField field : fields) {
            fieldStrings.add(String.valueOf(field));
        }
        return this.addFields(fieldStrings); 
    }

    global SoqlQuery addFields(SObjectField field) {
        return this.addFields(new List<SObjectField>{field});
    }

    global SoqlQuery addFields(List<String> fields) {
        this.fields.addAll(fields); 
        return this; 
    }

    global SoqlQuery addFields(String field) {
        return this.addFields(new List<String>{field});
    }

    global SoqlQuery resetFields() {
        this.fields = new Set<String>{'Id'};
        return this; 
    }

    global SoqlQuery addFilters(List<QueryFilter> filters) {
        this.filters.addAll(filters); 
        return this;
    }

    global SoqlQuery addFilters(QueryFilter filter) {
        return this.addFilters(new List<QueryFilter>{filter});
    }

    global SoqlQuery resetFilters() {
        this.filters.clear();
        return this;
    }

    global SoqlQuery setFilterLogic(String formattedLogicString) {
        // Expects a String.format() template with and/or logic in between
        // i.e., '{0} AND {1} AND ({2} OR {3})'
        this.filterLogic = formattedLogicString;
        return this;
    }

    global SoqlQuery resetFilterLogic() {
        return this.setFilterLogic(null); 
    }

    global SoqlQuery setOrderBy(QuerySort orderBy) {
        this.orderBy = orderBy;
        return this; 
    }

    global SoqlQuery resetOrderBy() {
        this.orderBy = null; 
        return this; 
    }

    global SoqlQuery setLimit(Integer queryLimit) {
        this.queryLimit = queryLimit; 
        return this;
    }

    global SoqlQuery resetLimit() {
        return this.setLimit(null); 
    }

    global SoqlQuery addTags(List<String> queryTags) {
        this.queryTags.addAll(queryTags);
        return this; 
    }

    global SoqlQuery addTags(String queryTag) {
        return this.addTags(new List<String>{queryTag});
    }

    global SoqlQuery resetTags() {
        this.queryTags.clear();
        return this; 
    }
    
    global SoqlQuery reset() {
        this.resetFields();
        this.resetFilters();
        this.resetFilterLogic(); 
        this.resetOrderBy(); 
        this.resetLimit();
        this.resetTags(); 
        return this; 
    }

    // **** PRIVATE **** // 
    private String getWhereClause() {
        return (this.filters?.isEmpty() == false)
            ? ' WHERE ' + this.joinFilters()
            : '';
    }

    private String joinFilters() {
        List<String> filterStrings = new List<String>(); 
        for (QueryFilter filter : this.filters) {
            filterStrings.add(filter.toString()); 
        }
        return (this.filterLogic != null) 
            ? String.format(this.filterLogic, filterStrings)
            : String.join(filterStrings, ' AND ');
    }

    private String getOrderByClause() {
        return (this.orderBy != null) ? ' ORDER BY ' + this.orderBy.toString() : '';
    }

    private String getLimitClause() {
        return (this.queryLimit != null) ? ' LIMIT ' + this.queryLimit : '';
    }

    private String getSpecialTags() {
        return (this.queryTags?.isEmpty() == false) ? ' ' + String.join(this.queryTags, ' ') : '';
    }
}