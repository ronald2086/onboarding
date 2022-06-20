"""initial

Revision ID: 108b300800fe
Revises: 
Create Date: 2022-05-26 16:00:06.741180

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '108b300800fe'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():

    op.create_table('org',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('Ext_Provider', sa.String(), nullable=True),
                    sa.Column('Ext_Provider_Key', sa.String(), nullable=True),
                    sa.Column('Ext_Provider_URL', sa.String(), nullable=True),
                    sa.Column('Ext_Provider_UserName', sa.String(), nullable=True),
                    sa.Column('Manage_API_Key', sa.String(), nullable=True),
                    sa.Column('Manage_Org_Id', sa.String(), nullable=True),
                    sa.Column('Manage_Org_Name', sa.String(), nullable=True),
                    sa.Column('Manage_URL', sa.String(), nullable=True),
                    sa.Column('Manage_UserName', sa.String(), nullable=True),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_org_id'), 'org', ['id'], unique=False)
    op.create_table('data_server',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('name', sa.String(), nullable=False),
                    sa.Column('address', sa.String(), nullable=True),
                    sa.Column('org_id', sa.Integer(), nullable=True),
                    sa.ForeignKeyConstraint(['org_id'], ['org.id'], ),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_data_server_id'), 'data_server', ['id'], unique=False)
    op.create_table('floor',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('Ext_Building_Id', sa.String(), nullable=True),
                    sa.Column('Ext_Floor_Id', sa.String(), nullable=True),
                    sa.Column('Manage_Building_Id', sa.String(), nullable=True),
                    sa.Column('Manage_Building_Name', sa.String(), nullable=True),
                    sa.Column('Manage_Floor_Id', sa.String(), nullable=True),
                    sa.Column('Manage_Floor_Name', sa.String(), nullable=True),
                    sa.Column('Manage_Org_Id', sa.String(), nullable=True),
                    sa.Column('Manage_Site_Id', sa.String(), nullable=True),
                    sa.Column('Manage_Site_Name', sa.String(), nullable=True),
                    sa.Column('org_id', sa.Integer(), nullable=True),
                    sa.ForeignKeyConstraint(['org_id'], ['org.id'], ),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_floor_id'), 'floor', ['id'], unique=False)
    op.create_table('zone_room',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('Ext_Boundary_Points', sa.String(), nullable=True),
                    sa.Column('Ext_Floor_Id', sa.String(), nullable=True),
                    sa.Column('Ext_Room_Id', sa.String(), nullable=True),
                    sa.Column('Ext_Room_Name', sa.String(), nullable=True),
                    sa.Column('Ext_Zone_Id', sa.String(), nullable=True),
                    sa.Column('Ext_Zone_Name', sa.String(), nullable=True),
                    sa.Column('Ext_Zone_Room_Name', sa.String(), nullable=True),
                    sa.Column('floor_id', sa.Integer(), nullable=True),
                    sa.Column('org_id', sa.Integer(), nullable=True),
                    sa.ForeignKeyConstraint(['floor_id'], ['floor.id'], ),
                    sa.ForeignKeyConstraint(['org_id'], ['org.id'], ),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_zone_room_id'), 'zone_room', ['id'], unique=False)
    op.create_table('dc_sessions',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('username', sa.String(), nullable=True),
                    sa.Column('org_id', sa.Integer(), nullable=True),
                    sa.Column('floor_id', sa.Integer(), nullable=True),
                    sa.Column('zone_room_id', sa.Integer(), nullable=True),
                    sa.Column('tag_ids', sa.Integer(), nullable=True),
                    sa.Column('session_name', sa.String(), nullable=True),
                    sa.Column('percent_completed', sa.Integer(), nullable=True),
                    sa.Column('dataServer_id', sa.Integer(), nullable=True),
                    sa.Column('created_at', sa.DateTime(), nullable=True),
                    sa.Column('updated_at', sa.DateTime(), nullable=True),
                    sa.ForeignKeyConstraint(['dataServer_id'], ['data_server.id'], ),
                    sa.ForeignKeyConstraint(['floor_id'], ['floor.id'], ),
                    sa.ForeignKeyConstraint(['org_id'], ['org.id'], ),
                    sa.ForeignKeyConstraint(['zone_room_id'], ['zone_room.id'], ),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_dc_sessions_id'), 'dc_sessions', ['id'], unique=False)
    op.create_table('user',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('username', sa.String(), nullable=True),
                    sa.Column('pwd_hash', sa.String(), nullable=True),
                    sa.Column('name', sa.String(), nullable=True),
                    sa.Column('role', sa.String(), nullable=True),
                    sa.Column('created_at', sa.DateTime(), nullable=True),
                    sa.Column('updated_at', sa.DateTime(), nullable=True),
                    sa.Column('dc_sessions_id', sa.Integer(), nullable=True),
                    sa.ForeignKeyConstraint(['dc_sessions_id'], ['dc_sessions.id'], ),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_user_id'), 'user', ['id'], unique=False)
    op.create_index(op.f('ix_user_username'), 'user', ['username'], unique=True)


def downgrade():
    op.drop_index(op.f('ix_user_username'), table_name='user')
    op.drop_index(op.f('ix_user_id'), table_name='user')
    op.drop_table('user')
    op.drop_index(op.f('ix_dc_sessions_id'), table_name='dc_sessions')
    op.drop_table('dc_sessions')
    op.drop_index(op.f('ix_zone_room_id'), table_name='zone_room')
    op.drop_table('zone_room')
    op.drop_index(op.f('ix_floor_id'), table_name='floor')
    op.drop_table('floor')
    op.drop_index(op.f('ix_data_server_id'), table_name='data_server')
    op.drop_table('data_server')
    op.drop_index(op.f('ix_org_id'), table_name='org')
    op.drop_table('org')
