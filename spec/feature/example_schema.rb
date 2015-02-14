module ExampleSchema

  def create_tables
    create_source_tables
    create_target_tables
  end

  def drop_tables
    drop_source_tables
    drop_target_tables
  end

  def create_source_tables
    test_database.create_schema :source

    test_database.create_table :source__Organisation do
      Integer :pkOrgId
      String :Name, size: 255
      String :Adresse, size: 255
      String :Abteilung, size: 255
    end
  end

  def drop_source_tables
    test_database.drop_schema :source, cascade: true
  end

  def create_target_tables
    test_database.create_table :organisations do
      primary_key :id
      String :external_id, size: 255
      String :external_source, size: 255
      String :name, size: 255
      String :address, size: 255
      DateTime :created_at
      DateTime :updated_at
      DateTime :deleted_at
    end

    test_database.create_table :departments do
      primary_key :id
      String :external_id, size: 255
      String :external_source, size: 255
      String :name, size: 255
      foreign_key :organisation_id, :organisations
      DateTime :created_at
      DateTime :updated_at
      DateTime :deleted_at
    end
  end

  def drop_target_tables
    test_database.drop_table :departments
    test_database.drop_table :organisations
  end

end
