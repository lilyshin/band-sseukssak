defmodule BandCore.ErrorCodes do
  @moduledoc """
  Band Open API 에러 코드 정의 및 처리
  """

  require Logger

  @error_codes %{
    # 기본 에러
    211 => %{
      message: "Invalid Parameters",
      description: "잘못된 파라미터",
      resolution: "파라미터를 확인하고 수정해 주세요."
    },
    212 => %{
      message: "Insufficient Parameters", 
      description: "필수 파라미터 누락",
      resolution: "필수 파라미터를 확인하고 추가해 주세요."
    },
    
    # 쿼터 및 제한 에러
    1001 => %{
      message: "App quota has been exceeded",
      description: "앱 쿼터 초과",
      resolution: "쿼터가 재설정될 때까지 기다려 주세요."
    },
    1002 => %{
      message: "User quota has been exceeded",
      description: "사용자별 쿼터 초과",
      resolution: "쿼터가 재설정될 때까지 기다려 주세요."
    },
    1003 => %{
      message: "Cool down time restriction",
      description: "쿨타임 제한(짧은 시간 안에 연속 호출 불가)",
      resolution: "쿨타임 제한이 해제된 후에 다시 시도하세요."
    },
    
    # 권한 에러
    2142 => %{
      message: "Only Band Leaders are allowed to do this",
      description: "밴드 리더만 허용하는 기능",
      resolution: "밴드 리더 권한이 필요합니다."
    },
    
    # 서버 에러
    2300 => %{
      message: "Invalid response",
      description: "서버 응답 오류",
      resolution: "정의되지 않은 오류입니다. 클라이언트 ID와 요청 URL, 파라미터 정보를 첨부하여 고객센터에 문의해 주세요."
    },
    
    # 요청 에러
    3000 => %{
      message: "Invalid request",
      description: "잘못된 호출",
      resolution: "경로 및 파라미터 확인 후 다시 시도하세요."
    },
    3001 => %{
      message: "Exceeded character limit",
      description: "문자열의 길이 제한 초과",
      resolution: "문자열 길이 조정 후 다시 시도하세요."
    },
    3002 => %{
      message: "Image file size has been exceeded",
      description: "첨부 이미지 파일 크기 제한 초과",
      resolution: "이미지 파일 크기를 줄여서 다시 시도하세요."
    },
    3003 => %{
      message: "Number of image files has been exceeded",
      description: "첨부 이미지 갯수 제한 초과",
      resolution: "첨부 이미지 수를 줄여서 다시 시도하세요."
    },
    
    # 인증 에러
    10401 => %{
      message: "Unauthorized",
      description: "인증 실패(인증 토큰이 없거나 만료된 경우)",
      resolution: "로그인하여 새로 인증 토큰을 받아서 다시 시도하세요."
    },
    10403 => %{
      message: "Forbidden",
      description: "접근 차단(권한이 없는 경우)",
      resolution: "해당 기능 사용 권한을 확인해 주시고, 권한을 추가하려면 고객센터로 문의해 주세요."
    },
    
    # 파라미터 에러
    60000 => %{
      message: "Invalid Parameter",
      description: "잘못된 파라미터",
      resolution: "필수 파라미터 확인, 파라미터 타입 확인 후 다시 시도하세요."
    },
    
    # 사용자 관련 에러
    60100 => %{
      message: "Invalid member",
      description: "존재하지 않는 사용자",
      resolution: "사용자 정보를 확인해 주세요."
    },
    60101 => %{
      message: "Not my friend",
      description: "사용자의 친구가 아님",
      resolution: "친구 관계를 확인해 주세요."
    },
    60102 => %{
      message: "Not Band member",
      description: "밴드 멤버가 아님(가입하지 않은 밴드에 접근하는 경우)",
      resolution: "밴드 가입 여부를 확인해 주세요."
    },
    60103 => %{
      message: "This user is not connected",
      description: "연동하지 않은 사용자",
      resolution: "사용자 연동을 확인해 주세요."
    },
    60104 => %{
      message: "This user has already been connected",
      description: "이미 연동한 사용자",
      resolution: "이미 연동된 사용자입니다."
    },
    60105 => %{
      message: "You are Band Leader. Band has members.",
      description: "멤버가 있는데 리더가 탈퇴 시도하는 경우",
      resolution: "리더 권한을 위임한 후 탈퇴해 주세요."
    },
    60106 => %{
      message: "This function is granted to the specified member.",
      description: "특정 멤버에게만 권한이 부여된 기능",
      resolution: "해당 기능을 사용할 권한이 없습니다."
    },
    
    # 밴드 관련 에러
    60200 => %{
      message: "This Band is invalid or not connected.",
      description: "없는 밴드이거나 연동되지 않은 밴드",
      resolution: "밴드 정보를 확인해 주세요."
    },
    60201 => %{
      message: "You have already joined Band",
      description: "이미 가입한 밴드",
      resolution: "이미 가입된 밴드입니다."
    },
    60202 => %{
      message: "Exceeded Band Max.",
      description: "가입할 수 있는 최대 밴드 수 초과",
      resolution: "기존 밴드를 탈퇴한 후 다시 시도해 주세요."
    },
    60203 => %{
      message: "Band not connected to app",
      description: "앱과 연동된 밴드가 아님",
      resolution: "앱과 연동된 밴드인지 확인해 주세요."
    },
    60204 => %{
      message: "This Band did not allow access by the user.",
      description: "사용자가 접근 불가 설정된 밴드에 접근하는 경우",
      resolution: "밴드 접근 권한을 확인해 주세요."
    },
    
    # 메시지 관련 에러
    60300 => %{
      message: "Receiving message is blocked",
      description: "상대방이 메시지 수신 거부 상태",
      resolution: "메시지 수신 설정을 확인해 주세요."
    },
    60301 => %{
      message: "Invalid message format",
      description: "메시지 형식이 올바르지 않음",
      resolution: "메시지 형식을 확인해 주세요."
    },
    60302 => %{
      message: "Message service error",
      description: "메시지 서비스 오류",
      resolution: "잠시 후 다시 시도해 주세요."
    },
    
    # 게시글 관련 에러
    60400 => %{
      message: "Only designated member(s) can write post",
      description: "글쓰기 권한 없음",
      resolution: "글쓰기 권한을 확인해 주세요."
    },
    60401 => %{
      message: "Post not connected to app",
      description: "앱과 연동된 포스트가 아님",
      resolution: "앱과 연동된 게시글인지 확인해 주세요."
    },
    60402 => %{
      message: "Post cannot be modified",
      description: "포스트 수정 불가(image 혹은 subpost가 삭제된 경우)",
      resolution: "게시글 상태를 확인해 주세요."
    },
    
    # 초대 관련 에러
    60700 => %{
      message: "This invitation is invalid",
      description: "초대장이 유효하지 않음",
      resolution: "초대장을 다시 확인해 주세요."
    },
    
    # 이미지/앨범 관련 에러
    60800 => %{
      message: "Image URL is invalid or the format is not supported",
      description: "유효하지 않은 형식의 이미지 URL",
      resolution: "이미지 URL 형식을 확인해 주세요."
    },
    60801 => %{
      message: "Album not exists",
      description: "존재하지 않은 앨범 ID",
      resolution: "앨범 ID를 확인해 주세요."
    }
  }

  @doc """
  에러 코드에 대한 정보를 반환합니다.
  """
  def get_error_info(code) when is_integer(code) do
    Map.get(@error_codes, code)
  end
  
  def get_error_info(code) when is_binary(code) do
    case Integer.parse(code) do
      {int_code, ""} -> get_error_info(int_code)
      _ -> nil
    end
  end
  
  def get_error_info(_), do: nil

  @doc """
  에러 로그를 기록합니다.
  """
  def log_error(code, context \\ %{}) do
    case get_error_info(code) do
      nil ->
        Logger.error("Unknown Band API error code: #{code}, context: #{inspect(context)}")
        
      error_info ->
        Logger.error("""
        Band API Error - Code: #{code}
        Message: #{error_info.message}
        Description: #{error_info.description}
        Resolution: #{error_info.resolution}
        Context: #{inspect(context)}
        """)
    end
  end

  @doc """
  에러 응답을 파싱하고 로그를 기록합니다.
  """
  def handle_error_response(response, context \\ %{}) do
    case response do
      %{"result_code" => code} when code != 1 ->
        # result_code가 1이 아니면 에러
        log_error(code, Map.put(context, :response, response))
        get_user_friendly_message(code)
        
      %{"result_data" => %{"message" => message}} ->
        # result_data에 message가 있는 경우
        Logger.error("Band API Error - Message: #{message}, Context: #{inspect(context)}")
        message
        
      _ ->
        Logger.error("Band API Error - Unknown error format: #{inspect(response)}, Context: #{inspect(context)}")
        "알 수 없는 오류가 발생했습니다."
    end
  end

  @doc """
  사용자에게 보여줄 친화적인 에러 메시지를 반환합니다.
  """
  def get_user_friendly_message(code) do
    case get_error_info(code) do
      nil -> "알 수 없는 오류가 발생했습니다. (코드: #{code})"
      error_info -> error_info.description
    end
  end

  @doc """
  재시도 가능한 에러인지 확인합니다.
  """
  def retryable?(code) do
    code in [1003, 2300, 60302]  # 쿨타임, 서버 오류, 메시지 서비스 오류
  end

  @doc """
  권한 관련 에러인지 확인합니다.
  """
  def permission_error?(code) do
    code in [2142, 10401, 10403, 60106, 60400]
  end

  @doc """
  모든 에러 코드 목록을 반환합니다.
  """
  def all_error_codes, do: Map.keys(@error_codes)
end