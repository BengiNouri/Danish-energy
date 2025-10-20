"""baseline from SQL files

Revision ID: 91a63019384f
Revises: 0e577e5ac11d
Create Date: 2025-07-11 00:37:57.026787

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '91a63019384f'
down_revision: Union[str, None] = '0e577e5ac11d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
