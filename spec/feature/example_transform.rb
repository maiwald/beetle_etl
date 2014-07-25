import :organisations do
  query <<-SQL
    INSERT INTO #{stage_table} (
      external_id,
      import_run_id,
      name
    )

    SELECT DISTINCT
      o."Name",
      #{import_run_id},
      o."Name"

    FROM source."Organisation" o
  SQL
end

import :departments do
  references :organisations, on: :organisation_id

  query <<-SQL
    INSERT INTO #{stage_table} (
      external_id,
      import_run_id,
      name,
      external_organisation_id
    )

    SELECT
      #{combined_key('o."Name"', 'o."pkOrgId"')},
      #{import_run_id},
      o."Abteilung",
      o."Name"

    FROM source."Organisation" o
  SQL
end
