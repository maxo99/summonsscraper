import uuid
from datetime import datetime, date
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


# Pydantic Models
class SearchQuery(BaseModel):
    business: str
    startDate: str
    endDate: str


class Query(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    county: str
    searches: List[SearchQuery]
    timestamp: datetime = Field(default_factory=datetime.now)
    status: str = "pending"  # pending, completed, failed
    step_function_arn: Optional[str] = None


class Case(BaseModel):
    caseId: str
    business: str
    filingDate: date
    defendant: str
    caseName: Optional[str] = None
    loaded: date = Field(default_factory=date.today)
    caseStatus: str
    addresses: List[str] = Field(default_factory=list)
    other: Dict[str, Any] = Field(default_factory=dict)
    query_id: str
    user_status: Optional[str] = None  # sent, response, contract
