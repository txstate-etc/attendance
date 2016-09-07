# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Role.create([
  {
    roletype: 'Instructor',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/Instructor',
    displayname: 'Instructor',
    displayorder: 0,
    sets_permissions: true,
    take_attendance: true,
    record_attendance: false,
    edit_gradesettings: true
  },
  {
    roletype: 'Learner/Instructor',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/Learner/Instructor',
    displayname: 'Project Maintainer',
    displayorder: 1,
    sets_permissions: true,
    take_attendance: true,
    record_attendance: true,
    edit_gradesettings: true
  },
  {
    roletype: 'TeachingAssistant',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/TeachingAssistant',
    displayname: 'Teaching Assistant',
    displayorder: 2,
    sets_permissions: false,
    take_attendance: true,
    record_attendance: false,
    edit_gradesettings: true
  },
  {
    roletype: 'TeachingAssistant/Grader',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/TeachingAssistant/Grader',
    displayname: 'Grader',
    displayorder: 3,
    sets_permissions: false,
    take_attendance: false,
    record_attendance: false,
    edit_gradesettings: false
  },
  {
    roletype: 'Member',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/Member',
    displayname: 'Project Participant',
    displayorder: 4,
    sets_permissions: false,
    take_attendance: false,
    record_attendance: true,
    edit_gradesettings: false
  },
  {
    roletype: 'Learner',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/Learner',
    displayname: 'Student',
    displayorder: 5,
    sets_permissions: false,
    take_attendance: false,
    record_attendance: true,
    edit_gradesettings: false
  },
  {
    roletype: 'Instructor/GuestInstructor',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/Instructor/GuestInstructor',
    displayname: 'Site Assistant',
    displayorder: 6,
    sets_permissions: false,
    take_attendance: false,
    record_attendance: false,
    edit_gradesettings: false
  },
  {
    roletype: 'Instructor/ExternalInstructor',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/Instructor/ExternalInstructor',
    displayname: 'Site Collaborator',
    displayorder: 7,
    sets_permissions: false,
    take_attendance: false,
    record_attendance: false,
    edit_gradesettings: false
  },
  {
    roletype: 'Learner/GuestLearner',
    subroletype: '',
    roleurn: 'urn:lti:role:ims/lis/Learner/GuestLearner',
    displayname: 'Guest',
    displayorder: 8,
    sets_permissions: false,
    take_attendance: false,
    record_attendance: false,
    edit_gradesettings: false
  }
])

Attendancetype.create([
  {
    name: 'Present',
    description: 'Student attended class normally.',
    display_column: 0,
    color: '#0d6325',
    absent: false,
    default_type: true,
    default_inactive: false,
    default_created: false,
    display_order: 0,
    grade_type: 0
  },
  {
    name: 'Absent',
    description: 'Student did not attend class.',
    display_column: 1,
    color: '#c60f13',
    absent: true,
    default_type: false,
    default_inactive: true,
    default_created: false,
    display_order: 1,
    grade_type: 2
  },
  {
    name: 'Late',
    description: 'Student was late to class.',
    display_column: 1,
    color: '#daa520',
    absent: false,
    default_type: false,
    default_inactive: false,
    default_created: false,
    display_order: 2,
    grade_type: 1
  },
  {
    name: 'Excused',
    description: 'Student was excused for illness or other reason.',
    display_column: 1,
    color: '#424141',
    absent: true,
    default_type: false,
    default_inactive: false,
    default_created: true,
    display_order: 3,
    grade_type: 0
  }
])
