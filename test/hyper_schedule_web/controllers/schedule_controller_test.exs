defmodule HyperScheduleWeb.ScheduleControllerTest do
  use HyperScheduleWeb.ConnCase

  test "POST /api/v1/schedule", %{conn: conn} do
    conn =
      post(conn, "/api/v1/schedule", %{
        "dates" => [
          "2020-12-25T23:50:07Z",
          "2020-12-26T23:50:07Z",
          "2020-12-27T23:50:07Z",
          "2020-12-28T23:50:07Z"
        ],
        "participants" => [
          %{
            "name" => "Hiya",
            "blocked" => [
              "2020-12-26T23:50:07Z"
            ],
            "scheduled" => []
          },
          %{
            "name" => "Hiya2",
            "blocked" => [
              "2020-12-27T23:50:07Z"
            ],
            "scheduled" => []
          },
          %{
            "name" => "Hiya3",
            "blocked" => [
              "2020-12-28T23:50:07Z"
            ],
            "scheduled" => []
          }
        ]
      })

    assert json_response(conn, 200) == [
             %{
               "blocked" => ["2020-12-26T23:50:07Z"],
               "name" => "Hiya",
               "scheduled" => ["2020-12-25T00:00:01Z", "2020-12-28T00:00:01Z"]
             },
             %{
               "blocked" => ["2020-12-27T23:50:07Z"],
               "name" => "Hiya2",
               "scheduled" => ["2020-12-26T00:00:01Z"]
             },
             %{
               "blocked" => ["2020-12-28T23:50:07Z"],
               "name" => "Hiya3",
               "scheduled" => ["2020-12-27T00:00:01Z"]
             }
           ]
  end
end
