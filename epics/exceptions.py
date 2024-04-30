from rest_framework.exceptions import APIException


class BadCommand(Exception):
    ...


class APIBadCommand(APIException):
    status_code = 420
    default_detail = 'Operation not allowed'
    default_code = 'operation_not_allowed'

    def __init__(self, detail, **kwargs):
        super().__init__(**kwargs)
        self.detail = f"{self.default_detail}: {detail}"
