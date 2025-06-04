defmodule BandWebWeb.ErrorJSON do
  @moduledoc """
  JSON API 에러 응답 처리
  """

  # 500 에러 (내부 서버 오류)
  def render("500.json", _assigns) do
    %{
      success: false,
      error: "서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
      message: "🧹 밴쓱싹이 열심히 문제를 해결하고 있어요!",
      code: 500
    }
  end

  # 404 에러 (페이지 없음)
  def render("404.json", _assigns) do
    %{
      success: false,
      error: "요청하신 리소스를 찾을 수 없습니다.",
      message: "🔍 올바른 URL인지 확인해주세요!",
      code: 404
    }
  end

  # 400 에러 (잘못된 요청)
  def render("400.json", _assigns) do
    %{
      success: false,
      error: "잘못된 요청입니다.",
      message: "📝 요청 형식을 확인해주세요!",
      code: 400
    }
  end

  # 401 에러 (인증 필요)
  def render("401.json", _assigns) do
    %{
      success: false,
      error: "인증이 필요합니다.",
      message: "🔐 로그인 후 다시 시도해주세요!",
      code: 401
    }
  end

  # 403 에러 (권한 없음)
  def render("403.json", _assigns) do
    %{
      success: false,
      error: "권한이 없습니다.",
      message: "⛔ 이 작업을 수행할 권한이 없어요!",
      code: 403
    }
  end

  # 기타 에러들
  def render(template, _assigns) do
    %{
      success: false,
      error: Phoenix.Controller.status_message_from_template(template),
      message: "💫 예상치 못한 문제가 발생했어요!",
      code: extract_status_code(template)
    }
  end

  defp extract_status_code(template) do
    case String.split(template, ".") do
      [status_code | _] ->
        case Integer.parse(status_code) do
          {code, ""} -> code
          _ -> 500
        end
      _ -> 500
    end
  end
end
