module ExampleSchema

  def create_tables
    create_source_tables
    create_stage_tables
    create_target_tables
  end

  def drop_tables
    drop_source_tables
    drop_stage_tables
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

  def create_stage_tables
    test_database.create_schema :stage

    test_database.create_table :stage__import_runs do
      primary_key :id
      DateTime :started_at
      DateTime :finished_at
      String :state, size: 255
    end

    test_database.create_table :stage__organisations do
      Integer :id
      String :external_id, size: 255
      foreign_key :import_run_id, :stage__import_runs
      index [:external_id, :import_run_id]
      String :transition, size: 255

      String :name, size: 255
      String :address, size: 255
    end

    test_database.create_table :stage__departments do
      Integer :id
      String :external_id, size: 255
      foreign_key :import_run_id, :stage__import_runs
      index [:external_id, :import_run_id]
      String :transition, size: 255

      String :name, size: 255

      String :external_organisation_id, size: 255
      Integer :organisation_id

    end

  end

  def drop_stage_tables
    test_database.drop_schema :stage, cascade: true
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
