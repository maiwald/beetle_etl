import :organisations do
  query <<-SQL
    INSERT INTO #{stage_table} (
      external_id,
      address,
      name
    )

    SELECT DISTINCT
      o."Name",
      o."Adresse",
      o."Name"

    FROM source."Organisation" o
  SQL
end

import :departments do
  columns :name
  references :organisations, on: :organisation_id

  query <<-SQL
    INSERT INTO #{stage_table} (
      external_id,
      name,
      external_organisation_id
    )

    SELECT
      #{combined_key('o."Name"', 'o."pkOrgId"')},
      o."Abteilung",
      o."Name"

    FROM source."Organisation" o
  SQL
end
